package JSV::Compiler;
use strict;
use warnings;
use JSON;
use JSON::Pointer;
use URI;
use Path::Tiny;
use Carp;
use Storable 'dclone';
use Data::Dumper;
use Regexp::Common('RE_ALL', 'Email::Address', 'URI', 'time');
use Scalar::Util qw(looks_like_number blessed weaken reftype);

our $VERSION = "0.05";

sub new {
    my ($class, %args) = @_;
    bless {
        original_schema => {},
        full_schema     => {},
    }, $class;
}

sub load_schema {
    my ($self, $file) = @_;
    if ('HASH' eq ref $file) {
        $self->{original_schema} = $file;
    } else {
        croak "Unreadable file" if !-r $file;
        if ($file =~ /\.yaml$/i || $file =~ /\.yml$/i) {
            require YAML::XS;
            $self->{original_schema} = YAML::XS::LoadFile($file);
        } elsif ($file =~ /\.json/i) {
            $self->{original_schema} = decode_json(path($file)->slurp_raw);
        } else {
            croak "Unknown file type: must be .json or .yaml";
        }
    }
    return $self->_resolve_references;
}

sub _deep_walk {
    my $visitor = shift;
    my $recurse;
    ## no critic (Variables::RequireInitializationForLocalVars)
    local $_;
    $recurse = sub {
        my ($cnode) = @_;
        my $ctype = reftype $cnode;
        if ($ctype eq 'ARRAY') {
            my $index = 0;
            for (@$cnode) {
                my $dtype = reftype $_;
                if ($dtype && ($dtype eq 'HASH' || $dtype eq 'ARRAY')) {
                    $recurse->($_, $cnode);
                }
                $visitor->($ctype, $cnode, $index++);
            }
        } elsif ($ctype eq 'HASH') {
            for my $k (keys %$cnode) {
                local $_ = $cnode->{$k};
                my $dtype = reftype $_;
                if ($dtype && ($dtype eq 'HASH' || $dtype eq 'ARRAY')) {
                    $recurse->($_, $cnode);
                }
                $visitor->($ctype, $cnode, $k);
            }
        }
    };
    $recurse->($_[0]);
    $_ = $_[0];
    $visitor->('ARRAY', \@_, 0);
}

sub _resolve_references {    ## no critic (Subroutines::ProhibitExcessComplexity)
    my $self = $_[0];
    $self->{full_schema} = dclone $self->{original_schema};
    my $base_uri = $self->{full_schema}{id} || $self->{full_schema}{'$id'};
    if ($base_uri) {
        $base_uri = URI->new($base_uri)->canonical();
        $base_uri->fragment("") if not $base_uri->fragment;
        $self->{schemas}{$base_uri} = $self->{full_schema};
    }
    my @unresolved;
    my %unresolved;
    my $resolve = sub {
        my ($ref) = @_;
        my $uri = $base_uri ? URI->new_abs($ref, $base_uri)->canonical : URI->new($ref)->canonical;
        return $self->{schemas}{$uri} if $self->{schemas}{$uri};
        my $su = $uri->clone;
        $su->fragment("");
        if ($self->{schemas}{$su}) {
            my $rs = JSON::Pointer->get($self->{schemas}{$su}, $uri->fragment);
            return $rs if $rs;
        }
        push @unresolved, "$su" if not $unresolved{$su}++;
        return undef;
    };
    _deep_walk(
        sub {
            my ($ctype, $cnode, $index) = @_;
            if (   $ctype eq 'ARRAY'
                && 'HASH' eq ref $_
                && keys %$_ == 1
                && $_->{'$ref'}
                && !ref($_->{'$ref'}))
            {
                weaken($cnode->[$index] = $resolve->($_->{'$ref'}));
            } elsif ('HASH' eq ref $_) {
                for my $k (keys %$_) {
                    my $v = $_->{$k};
                    if ('HASH' eq ref($v) && keys(%$v) == 1 && $v->{'$ref'} && !ref($v->{'$ref'})) {
                        weaken($_->{$k} = $resolve->($v->{'$ref'}));
                    } elsif ($k eq '$ref' && !ref($_->{$k})) {
                        my $r = $resolve->($_->{$k});
                        if ($r && 'HASH' eq ref $r) {
                            weaken($cnode->{$index} = $r);
                        }
                    } elsif (($k eq 'id' || $k eq '$id') && !ref($v)) {
                        my $id = $base_uri ? URI->new_abs($v, $base_uri)->canonical : URI->new($v)->canonical;
                        weaken($self->{schemas}{$id} = $_) if not $self->{schemas}{$id};
                    }
                }
            }
        },
        $self->{full_schema}
    );
    return wantarray ? @unresolved : $self;
}

sub compile {
    my ($self, %opts) = @_;
    ## no critic (Variables::ProhibitLocalVars)
    local $self->{coersion} = $opts{coersion} // 0;
    local $self->{to_json}  = $opts{to_json}  // 0;
    $self->{required_modules} = {};
    my $input_sym   = $opts{input_symbole} // '$_[0]';
    my $schema      = _norm_schema($self->{full_schema});
    my $type        = $schema->{type} // _guess_schema_type($schema);
    my $is_required = $opts{is_required} // $type eq 'object' || 0;
    my $val_func    = "_validate_$type";
    my $val_expr    = $self->$val_func($input_sym, $schema, "", $is_required);
    return
      wantarray
      ? ($val_expr, map {$_ => [sort keys %{$self->{required_modules}{$_}}]} keys %{$self->{required_modules}})
      : $val_expr;
}

# type: six primitive types ("null", "boolean", "object", "array", "number", or "string"), or "integer"

sub _norm_schema {
    my $shmpt = $_[0];
    return +{
        type  => _guess_schema_type($shmpt),
        const => $shmpt
    } if 'HASH' ne ref $shmpt;
    $shmpt;
}

sub _guess_schema_type {    ## no critic (Subroutines::ProhibitExcessComplexity)
    my $shmpt = $_[0];
    if (my $class = blessed($shmpt)) {
        if ($class =~ /bool/i) {
            return 'boolean';
        } else {
            return 'object';
        }
    }
    if ('HASH' ne ref $shmpt) {
        return 'number' if looks_like_number($shmpt);
        return 'string';
    }
    return $shmpt->{type} if $shmpt->{type};
    return 'object'
      if defined $shmpt->{additionalProperties}
      or $shmpt->{patternProperties}
      or $shmpt->{properties}
      or defined $shmpt->{minProperties}
      or defined $shmpt->{maxProperties};
    return 'array'
      if defined $shmpt->{additionalItems}
      or defined $shmpt->{uniqueItems}
      or $shmpt->{items}
      or defined $shmpt->{minItems}
      or defined $shmpt->{maxItems};
    return 'number'
      if defined $shmpt->{minimum}
      or defined $shmpt->{maximum}
      or exists $shmpt->{exclusiveMinimum}
      or exists $shmpt->{exclusiveMaximum}
      or defined $shmpt->{multipleOf};
    return 'string';
}

sub _quote_var {
    my $s = $_[0];
    my $d = Data::Dumper->new([$s]);
    $d->Terse(1);
    my $qs = $d->Dump;
    substr($qs, -1, 1, '') if substr($qs, -1, 1) eq "\n";
    return $qs;
}

#<<<
my %formats = (
	'date-time' => $RE{time}{iso},
	email       => $RE{Email}{Address},
	uri         => $RE{URI},
	hostname    => '(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*'
				 . '(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z])[.]?)',
	ipv4        => $RE{net}{IPv4},
	ipv6        => $RE{net}{IPv6},
);
#>>>

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _validate_null {
    my ($self, $sympt, $schmptm, $path) = @_;
    my @sp = split /->/, $sympt;
    my $el = pop @sp;
    my $sh = join "->", @sp;
    my $ec = $sh ? "|| ('HASH' eq ref($sh) && !exists  ($sympt))" : '';
    return "push \@\$errors, \"$path must be null\" if defined($sympt) $ec;\n";
}

sub _validate_boolean {
    my ($self, $sympt, $schmpt, $path, $is_required) = @_;
    $schmpt = _norm_schema($schmpt);
    my $r = '';
    if (exists $schmpt->{default}) {
        my $val = _quote_var($schmpt->{default});
        $r = "$sympt = $val if not defined $sympt;\n";
    }
    $r .= "if(defined($sympt)) {\n";
    $r .= $self->_validate_schemas_array($sympt, $schmpt, $path);
    if (defined $schmpt->{const}) {
        $r .= "  { no warnings 'uninitialized';\n";
        my $not = $schmpt->{const} ? 'not' : "";
        $r .= "    push \@\$errors, \"$path must be \".($schmpt->{const}?'true':'false') if $not $sympt \n";
        $r .= "  }\n";
    }
    if ($self->{to_json}) {
        $r .= "  $sympt = (($sympt)? \\1: \\0);\n";
    } elsif ($self->{coersion}) {
        $r .= "  $sympt = (($sympt)? 1: 0);\n";
    }
    $r .= "}\n";
    if ($is_required) {
        $r .= "else {\n";
        $r .= "  push \@\$errors, \"$path is required\";\n";
        $r .= "}\n";
    }
    return $r;
}

sub _validate_string {
    my ($self, $sympt, $schmpt, $path, $is_required) = @_;
    $schmpt = _norm_schema($schmpt);
    my $r = '';
    if (defined $schmpt->{default}) {
        my $val = _quote_var($schmpt->{default});
        $r = "$sympt = $val if not defined $sympt;\n";
    }
    $r .= "if(defined($sympt)) {\n";
    $r .= $self->_validate_schemas_array($sympt, $schmpt, $path);
    if (defined $schmpt->{maxLength}) {
        $r .= "  push \@\$errors, '$path length must be not greater than ";
        $r .= "$schmpt->{maxLength}' if length($sympt) > $schmpt->{maxLength};\n";
    }
    if (defined $schmpt->{minLength}) {
        $r .= "  push \@\$errors, '$path length must be not less than ";
        $r .= "$schmpt->{minLength}' if length($sympt) < $schmpt->{minLength};\n";
    }
    if (defined $schmpt->{const}) {
        my $val = _quote_var($schmpt->{const});
        $r .= "  push \@\$errors, \"$path must be $schmpt->{const}\" if $sympt ne $val;\n";
    }
    if (defined $schmpt->{pattern}) {
        my $pattern = $schmpt->{pattern};
        $pattern =~ s/\\Q(.*?)\\E/quotemeta($1)/eg;
        $pattern =~ s/\\Q(.*)$/quotemeta($1)/eg;
        $pattern =~ s/"/\\"/g;
        $pattern =~ s|/|\\/|g;
        $r .= "  push \@\$errors, \"$path does not match pattern\" if $sympt !~ /$pattern/;\n";
    }
    if ($schmpt->{enum} && 'ARRAY' eq ref($schmpt->{enum}) && @{$schmpt->{enum}}) {
        my $can_list = join ", ", map {_quote_var($_)} @{$schmpt->{enum}};
        $self->{required_modules}{'List::Util'}{none} = 1;
        $r .= "  push \@\$errors, \"$path must be on of $can_list\" if none {\$_ eq $sympt} ($can_list);\n";
    }
    if ($schmpt->{format} && $formats{$schmpt->{format}}) {
        $r .= "  push \@\$errors, \"$path does not match format $schmpt->{format}\"";
        $r .= " if $sympt !~ /^$formats{$schmpt->{format}}\$/;\n";
    }
    if ($self->{to_json} || $self->{coersion}) {
        $r .= "  $sympt = \"$sympt\";\n";
    }
    $r .= "}\n";
    if ($is_required) {
        $r .= "else {\n";
        $r .= "  push \@\$errors, \"$path is required\";\n";
        $r .= "}\n";
    }
    return $r;
}

sub _validate_any_number {    ## no critic (Subroutines::ProhibitManyArgs Subroutines::ProhibitExcessComplexity)
    my ($self, $sympt, $schmpt, $path, $is_required, $re, $ntype) = @_;
    $schmpt = _norm_schema($schmpt);
    my $r = '';
    $ntype ||= '';
    if (defined $schmpt->{default}) {
        my $val = _quote_var($schmpt->{default});
        $r = "$sympt = $val if not defined $sympt;\n";
    }
    $r .= "if(defined($sympt)) {\n";
    $r .= $self->_validate_schemas_array($sympt, $schmpt, $path);
    $r .= "  {\n";
    $r .= "  if($sympt !~ /^$re\$/){ push \@\$errors, '$path does not look like $ntype number'; last }\n";
    my ($minimum, $exclusiveMinimum, $maximum, $exclusiveMaximum) =
      @{$schmpt}{qw(minimum exclusiveMinimum maximum exclusiveMaximum)};
    if (defined $minimum && $exclusiveMinimum) {
        $exclusiveMinimum = $minimum;
        undef $minimum;
    }
    if (defined $maximum && $exclusiveMaximum) {
        $exclusiveMaximum = $maximum;
        undef $maximum;
    }
    if (defined $minimum) {
        $r .= "  push \@\$errors, '$path must be not less than $minimum'";
        $r .= " if $sympt < $minimum;\n";
    }
    if (defined $exclusiveMinimum) {
        $r .= "  push \@\$errors, '$path must be greater than $exclusiveMinimum'";
        $r .= " if $sympt <= $exclusiveMinimum;\n";
    }
    if (defined $maximum) {
        $r .= "  push \@\$errors, '$path must be not greater than $maximum'";
        $r .= " if $sympt > $maximum;\n";
    }
    if (defined $exclusiveMaximum) {
        $r .= "  push \@\$errors, '$path must be less than $exclusiveMaximum'";
        $r .= " if $sympt >= $exclusiveMaximum;\n";
    }
    if (defined $schmpt->{const}) {
        $r .= "  push \@\$errors, '$path must be $schmpt->{const}' if $sympt != $schmpt->{const};\n";
    }
    if ($schmpt->{multipleOf}) {
        $self->{required_modules}{'POSIX'}{floor} = 1;
        $r .= "  push \@\$errors, '$path must be multiple of $schmpt->{multipleOf}'";
        $r .= " if $sympt / $schmpt->{multipleOf} !=  floor($sympt / $schmpt->{multipleOf});\n";
    }
    if ($schmpt->{enum} && 'ARRAY' eq ref($schmpt->{enum}) && @{$schmpt->{enum}}) {
        my $can_list = join ", ", map {_quote_var($_)} @{$schmpt->{enum}};
        $self->{required_modules}{'List::Util'}{none} = 1;
        $r .= "  push \@\$errors, '$path must be on of $can_list' if none {$_ == $sympt} ($can_list);\n";
    }
    if ($schmpt->{format} && $formats{$schmpt->{format}}) {
        $r .= "  push \@\$errors, '$path does not match format $schmpt->{format}'";
        $r .= " if $sympt !~ /^$formats{$schmpt->{format}}\$/;\n";
    }
    if ($self->{to_json} || $self->{coersion}) {
        $r .= "  $sympt += 0;\n";
    }
    $r .= "} }\n";
    if ($is_required) {
        $r .= "else {\n";
        $r .= "  push \@\$errors, \"$path is required\";\n";
        $r .= "}\n";
    }
    return $r;

}

sub _validate_number {
    my ($self, $sympt, $schmpt, $path, $is_required) = @_;
    return $self->_validate_any_number($sympt, $schmpt, $path, $is_required, $RE{num}{real});
}

sub _validate_integer {
    my ($self, $sympt, $schmpt, $path, $is_required) = @_;
    return $self->_validate_any_number($sympt, $schmpt, $path, $is_required, $RE{num}{int}, "integer");
}

sub _make_schemas_array {
    my ($self, $schemas, $rpath, $type) = @_;
    $schemas = [$schemas] if 'ARRAY' ne ref $schemas;
    my @tfa;
    for my $schm (@{$schemas}) {
        my $subschm  = _norm_schema($schm);
        my $stype    = $subschm->{type} // $type // _guess_schema_type($schm);
        my $val_func = "_validate_$stype";
        my $ivf      = $self->$val_func("\$_[0]", $subschm, "$rpath", "required");
        push @tfa, "  sub {my \$errors = []; $ivf; \@\$errors == 0}\n";
    }
    return "(" . join(",\n", @tfa) . ")";
}

sub _validate_all_of {
    my ($self, $schmpt, $sympt, $rpath) = @_;
    my $r = '';
    $self->{required_modules}{'List::Util'}{notall} = 1;
    $r .= "  {  my \@allOf = " . $self->_make_schemas_array($schmpt->{allOf}, $rpath, $schmpt->{type}) . ";\n";
    $r .= "    my \$stored_arg = ${sympt};\n";
    $r .= "    push \@\$errors, \"$rpath doesn't match all required schemas\" "
      . "if notall { \$_->(\$stored_arg, \"$rpath\") } \@allOf;\n";
    $r .= "  }\n";
    return $r;
}

sub _validate_any_of {
    my ($self, $schmpt, $sympt, $rpath) = @_;
    my $r = '';
    $self->{required_modules}{'List::Util'}{none} = 1;
    $r .= "  {  my \@anyOf = " . $self->_make_schemas_array($schmpt->{anyOf}, $rpath, $schmpt->{type}) . ";\n";
    $r .= "    my \$stored_arg = ${sympt};\n";
    $r .= "    push \@\$errors, \"$rpath doesn't match any required schema\""
      . " if none { \$_->(\$stored_arg, \"$rpath\") } \@anyOf;\n";
    $r .= "  }\n";
    return $r;
}

sub _validate_one_of {
    my ($self, $schmpt, $sympt, $rpath) = @_;
    my $r = '';
    $r .= "  {  my \@oneOf = " . $self->_make_schemas_array($schmpt->{oneOf}, $rpath, $schmpt->{type}) . ";\n";
    $r .= "    my \$stored_arg = ${sympt};\n";
    $r .= "    my \$m = 0; for my \$t (\@oneOf) { ++\$m if \$t->(\$stored_arg, \"$rpath\"); last if \$m > 1; }\n";
    $r .= "    push \@\$errors, \"$rpath doesn't match exactly one required schema\" if \$m != 1;\n";
    $r .= "  }\n";
    return $r;
}

sub _validate_not_of {
    my ($self, $schmpt, $sympt, $rpath) = @_;
    my $r = '';
    $self->{required_modules}{'List::Util'}{any} = 1;
    $r .= "  {  my \@notOf = " . $self->_make_schemas_array($schmpt->{not}, $rpath, $schmpt->{type}) . ";\n";
    $r .= "    my \$stored_arg = ${sympt};\n";
    $r .= "    push \@\$errors, \"$rpath matches a schema when must not\" "
      . " if any { \$_->(\$stored_arg, \"$rpath\") } \@notOf;\n";
    $r .= "  }\n";
    return $r;
}

sub _validate_schemas_array {
    my ($self, $sympt, $schmpt, $path) = @_;
    my $rpath = !$path ? "(object)" : $path;
    my $r = '';
    $r .= $self->_validate_any_of($schmpt, $sympt, $rpath) if defined $schmpt->{anyOf};
    $r .= $self->_validate_all_of($schmpt, $sympt, $rpath) if defined $schmpt->{allOf};
    $r .= $self->_validate_one_of($schmpt, $sympt, $rpath) if defined $schmpt->{oneOf};
    $r .= $self->_validate_not_of($schmpt, $sympt, $rpath) if defined $schmpt->{not};
    return $r;
}

sub _validate_object {    ## no critic (Subroutines::ProhibitExcessComplexity)
    my ($self, $sympt, $schmpt, $path, $is_required) = @_;
    $schmpt = _norm_schema($schmpt);
    my $rpath = !$path ? "(object)" : $path;
    my $ppref = $path  ? "$path/"   : "";
    my $r     = '';
    if ($schmpt->{default}) {
        my $val = _quote_var($schmpt->{default});
        $r = "  $sympt = $val if not defined $sympt;\n";
    }
    $r .= "if('HASH' eq ref($sympt)) {\n";
    $r .= $self->_validate_schemas_array($sympt, $schmpt, $path);
    if ($schmpt->{properties} && 'HASH' eq ref $schmpt->{properties}) {
        my %required;
        if ($schmpt->{required} && 'ARRAY' eq ref $schmpt->{required}) {
            %required = map {$_ => 1} @{$schmpt->{required}};
        }
        for my $k (keys %{$schmpt->{properties}}) {
            my $type = 'string';
            if ('HASH' eq ref $schmpt->{properties}{$k}) {
                $type = $schmpt->{properties}{$k}{type} // _guess_schema_type($schmpt->{properties}{$k});
            }
            my $val_func = "_validate_$type";
            my $qk       = _quote_var($k);
            $r .= $self->$val_func("${sympt}->{$qk}", $schmpt->{properties}{$k}, "$ppref$k", $required{$k});
        }
    }
    if (defined $schmpt->{minProperties}) {
        $schmpt->{minProperties} += 0;
        $r .= "  push \@\$errors, '$rpath must contain not less than $schmpt->{minProperties} properties'";
        $r .= " if keys %{$sympt} < $schmpt->{minProperties};\n";
    }
    if (defined $schmpt->{maxProperties}) {
        $schmpt->{maxProperties} += 0;
        $r .= "  push \@\$errors, '$rpath must contain not more than $schmpt->{maxProperties} properties'";
        $r .= " if keys %{$sympt} > $schmpt->{minProperties};\n";
    }
    my @pt;
    if (defined $schmpt->{patternProperties}) {
        for my $pt (keys %{$schmpt->{patternProperties}}) {
            my $type;
            $type = $schmpt->{patternProperties}{$pt}{type}
              // _guess_schema_type($schmpt->{patternProperties}{$pt});
            my $val_func = "_validate_$type";
            (my $upt = $pt) =~ s/"/\\"/g;
            $upt =~ s/\\Q(.*?)\\E/quotemeta($1)/eg;
            $upt =~ s/\\Q(.*)$/quotemeta($1)/eg;
            $upt =~ s|/|\\/|g;
            push @pt, $upt;
            my $ivf = $self->$val_func("\$_[0]", $schmpt->{patternProperties}{$pt}, "\$_[1]", "required");
            $r .= "  { my \@props = grep {/$upt/} keys %{${sympt}};";

            if ($schmpt->{properties} && 'HASH' eq ref $schmpt->{properties}) {
                my %apr = map {_quote_var($_) => undef} keys %{$schmpt->{properties}};
                $r .= "    my %defined_props = (" . join(", ", map {$_ => "undef"} keys %apr) . ");\n";
                $r .= "    \@props = grep {!exists \$defined_props{\$_} } \@props;\n";
            }
            $r .= "    my \$tf = sub { $ivf };\n";
            $r .= "    for my \$prop (\@props) {\n";
            $r .= "      \$tf->(${sympt}->{\$prop}, \"$ppref\${prop}\");\n";
            $r .= "    };\n";
            $r .= "  }\n";
        }
    }
    if (defined $schmpt->{additionalProperties}) {
        if (!ref($schmpt->{additionalProperties}) && !$schmpt->{additionalProperties}) {
            my %apr;
            $r .= "  {\n";
            if ($schmpt->{properties} && 'HASH' eq ref $schmpt->{properties}) {
                %apr = map {_quote_var($_) => undef} keys %{$schmpt->{properties}};
                $r .= "    my %allowed_props = (" . join(", ", map {$_ => "undef"} keys %apr) . ");\n";
                $r .= "    my \@unallowed_props = grep {!exists \$allowed_props{\$_} } keys %{${sympt}};\n";
                if (@pt) {
                    $r .=
                        "    \@unallowed_props = grep { "
                      . join("&&", map {"!/$_/"} @pt)
                      . " } \@unallowed_props;\n";
                }
                $r .= "    push \@\$errors, \"$rpath contains not allowed properties: \@unallowed_props\" ";
                $r .= " if \@unallowed_props;\n";
            } else {
                $r .= "    push \@\$errors, \"$rpath can't contain properties\" if %{${sympt}};\n";
            }
            $r .= "  }\n";
        }
    }
    $r .= "}\n";
    if ($is_required) {
        $r .= "else {\n";
        $r .= "  push \@\$errors, \"$rpath is required\";\n";
        $r .= "}\n";
    }
    return $r;
}

sub _validate_array {
    my ($self, $sympt, $schmpt, $path, $is_required) = @_;
    $schmpt = _norm_schema($schmpt);
    my $rpath = !$path ? "(object)" : $path;
    my $r = '';
    if ($schmpt->{default}) {
        my $val = _quote_var($schmpt->{default});
        $r = "  $sympt = $val if not defined $sympt;\n";
    }
    $r .= "if('ARRAY' eq ref($sympt)) {\n";
    $r .= $self->_validate_schemas_array($sympt, $schmpt, $path);
    if (defined $schmpt->{minItems}) {
        $r .= "  push \@\$errors, '$path must contain not less than $schmpt->{minItems} items'";
        $r .= " if \@{$sympt} < $schmpt->{minItems};\n";
    }
    if (defined $schmpt->{maxItems}) {
        $r .= "  push \@\$errors, '$path must contain not more than $schmpt->{maxItems} items'";
        $r .= " if \@{$sympt} > $schmpt->{maxItems};\n";
    }
    if (defined $schmpt->{uniqueItems}) {
        $r .= "  { my %seen;\n";
        $r .= "    for (\@{$sympt}) {\n";
        $r .= "      if(\$seen{\$_}) { push \@\$errors, '$path must contain only unique items'; last }\n";
        $r .= "      \$seen{\$_} = 1;\n";
        $r .= "    };\n";
        $r .= "  }\n";
    }
    if ($schmpt->{items}) {
        my $type     = $schmpt->{items}{type} // _guess_schema_type($schmpt->{items});
        my $val_func = "_validate_$type";
        my $ivf      = $self->$val_func("\$_[0]", $schmpt->{items}, "$path/[]", $is_required);
        $r .= "  { my \$tf = sub { $ivf };\n";
        $r .= "    \$tf->(\$_, \"$rpath\") for (\@{$sympt});\n";
        $r .= "  }\n";
    }
    $r .= "}\n";
    if ($is_required) {
        $path = "array" if $path eq "";
        $r .= "else {\n";
        $r .= "  push \@\$errors, \"$path is required\";\n";
        $r .= "}\n";
    }
    return $r;
}

1;

__END__
 
=encoding utf-8
 
=head1 NAME
 
JSV::Compiler - Translates JSON-Schema validation rules (draft-06) into perl code
 
=head1 SYNOPSIS
 
  use JSV::Compiler;
  use Module::Load;
  
  my $jsv = JSV::Compiler->new;
  $jsv->load_schema({
    type => "object",
    properties => {
      foo => { type => "integer" },
      bar => { type => "string" }
    },
    required => [ "foo" ]
  });

  my ($vcode, %load) = $jsv->compile();

  for my $m (keys %load) {
    load $m, @{$load{$m}} ? @{$load{$m}} : ();
  }

  my $test_sub_txt = <<"SUB";
  sub { 
      my \$errors = []; 
      $vcode; 
      print "\@\$errors\\n" if \@\$errors;
      print "valid\n" if \@\$errors == 0;
      \@\$errors == 0;
  }
  SUB
  my $test_sub = eval $test_sub_txt;

  $test_sub->({}); # foo is required
  $test_sub->({ foo => 1 }); # valid
  $test_sub->({ foo => 10, bar => "xyz" }); # valid
  $test_sub->({ foo => 1.2, bar => "xyz" }); # foo does not look like integer number
 
=head1 DESCRIPTION
 
JSV::Compiler makes validation subroutine body in perl. 
You can then use it to embed in your own validation functions.
 
=head1 METHODS
 
=head2 load_schema($file|$hash)

Loads and registers schema. 
In list context returns list of URLs of unresolved schemas. You should
load all unresolved schemas and then load this one more time.
In scalar context returns C<$self>.
 
=head2 new

=head2 compile(%opts)

  my ($vcode, %load) = $jsv->compile();
  for my $m (keys %load) {
    load $m, @{$load{$m}} ? @{$load{$m}} : ();
  }

Returns compiled perl text. In list context it adds list of required modules
with array of their required import symbols.

=over

=item coersion => true|false

=item to_json => true|false

=item input_symbole => string to use for rood data structure access

=back

=head1 SUPPORTED KEYWORDS

Following keywords are supported:

=over

=item multipleOf

=item maximum

=item exclusiveMaximum

=item minimum

=item exclusiveMinimum

=item maxLength

=item minLength

=item pattern

=item items

=item maxItems

=item minItems

=item uniqueItems

=item maxProperties

=item minProperties

=item required

=item properties

=item patternProperties

=item additionalProperties

=item enum

=item const

=item type (single value)

=item allOf

=item anyOf

=item oneOf

=item not

=item default

=back

=head1 SEE ALSO
 
=over

=item L<http://json-schema.org/>
 
=item L<https://github.com/json-schema/JSON-Schema-Test-Suite>
 
=back

=head1 BUGS

It doesn't support all features of draft-06. For example, it doesn't support 
array of types and some type checks work in a little bit another way: every 
number in Perl is also string and C<type =E<gt> "string"> will be true for numbers.

It doesn't support B<contains> schema keyword. Almost everything else should 
be working. 

=head2 NOT YET SUPPORTED KEYWORDS

=over

=item additionalItems

=item contains

=item propertyNames

=back

=head1 LICENSE
 
Copyright (C) Anton Petrusevich
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=head1 AUTHOR
 
Anton Petrusevich E<lt>antonpetr@cpan.orgE<gt>
 
=cut
