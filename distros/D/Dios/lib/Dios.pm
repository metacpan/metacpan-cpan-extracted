package Dios;
our $VERSION = '0.002010';

use 5.014; use warnings;
use Dios::Types;
use Keyword::Declare;

my $PARAMETER_SYNTAX = qr{
    (?&WS)?+
    (?<raw_param>
        (?<nameless>
            (?<is_num_constant>    (?&PerlNumber)     )
        |
            (?<is_str_constant>    (?&PerlQuotelikeQ) )
        |
            (?<is_regex_constant>  (?&PerlMatch)      )
        )
    |
        # TYPE...
        (?<type> (?&TYPE_SPEC) )?+

        # NAME...
        (?&WS)?+
        (?<namedvar>
            : (?<name> (?&IDENT) ) \( (?&WS)?+
                (?<var> (?<sigil> [\$\@%]) (?&IDENT) ) (?&WS)?+
            \)
        |
            : (?<var> (?<sigil> [\$\@%])  (?<name> (?&IDENT) ) )
        |
            \* (?<slurpy>)
            (?:
                (?<var> (?<sigil> [\@%]) (?&IDENT) )
            |
                : (?<name> (?&IDENT) ) \( (?&WS)?
                    (?<var> (?<sigil> \@) (?&IDENT) ) (?&WS)?
                \)
            |
                : (?<var> (?<sigil> \@)  (?<name> (?&IDENT) ) )
            |
                (?<nameless> (?<sigil> [\@%]) )
            )
        |
            (?<var> (?<sigil> [\$\@%]) (?&IDENT) )
        |
            (?<nameless> (?<sigil> [\$\@%]?+) )
        )

        # OPTIONAL OR REQUIRED...
        (?: (?<default_type>  \? ) (?<default>    )
        |   (?<required>      \! )
        )?+

        # CONSTRAINT...
        (?&WS)?+
        (?: where (?&WS)?+ (?<constraint> (?&PerlBlock) ) )?+

        # READONLY OR ALIAS...
        (?: (?&WS)?+ is (?&WS)?+  (?<special> ro | alias ) )?+

        # DEFAULT VALUE...
        (?: (?&WS)?+ (?<default_type> (?> // | \|\| )?+ = )
            (?&WS)?+ (?<default> (?&PerlConditionalExpression) ))?+

        (?&WS)?+
    )
    (?<terminator> , | : | (?= --> ) | \z )

    (?(DEFINE)
        (?<TYPE_SPEC>  (?&TYPE_NAME) (?: [&|] (?&TYPE_NAME) )*+ )
        (?<TYPE_NAME>  (?&QUAL_IDENT)  (?&TYPE_PARAM)?+         )
        (?<TYPE_PARAM> \[ (?: [^][]*+ | (?&TYPE_PARAM) )*+ \]   )
        (?<QUAL_IDENT> (?&IDENT) (?: :: (?&IDENT) )*+           )
        (?<IDENT>      [^\W\d] \w*+                             )
        (?<WS>         (\s++ | \# [^\n]*+ \n )++                )
        $PPR::GRAMMAR
    )
}xms;

my $EMPTY_PARAM_LIST = qr{
    \A
    (?&OWS)
    (?:
        \(  (?&OWS)  (\*\@_)?+  (?&OWS)  \)
    )?+
    (?&OWS)
    \z

    (?(DEFINE)
        (?<OWS> \s*+ (?: \# .* \n \s*+ )*+ )
    )
}xm;

sub _translate_parameters {
    my $params   = shift;
    my $kind     = shift;
    my $sub_name = shift;
    my $sub_name_tidy = $sub_name;
    $sub_name_tidy =~ s{\A \s*+ (?: \# .*+ \n \s*+ )*+ }{}x;

    my $sub_desc = $sub_name ? "$kind $sub_name_tidy" : "anonymous $kind";
    my $invocant_name = $^H{'Dios invocant_name'} // '$self';

    # Empty and "standard" parameter lists are easy...
    if (!defined $params || $params =~ $EMPTY_PARAM_LIST) {
        my $std_slurpy = defined $1;
        my $code
            = ($kind eq 'method'
                ? _generate_invocant("method $sub_name_tidy", {var=>$invocant_name, sigil=>'$'})
                : q{}
              )
              . ($std_slurpy ? q{} : qq{Dios::_error(ucfirst(q{$sub_desc takes no arguments})) if \@_;});

        my $spec = ( $kind eq 'method' ? q{ {type=>'Any',    where=[]}, } : q{} )
                 . ( $std_slurpy       ? q{ {optional => 1, type=>'Slurpy', where=>[]} } : q{} );

        return { code => $code, spec => $spec };
    }

    $params =~ s{\A \s*+ \(}{}x;
    $params =~ s{\) \s*+ \z}{}x;

    my $return_type       = undef;
    my $return_constraint = undef;
    my $invocant          = $kind eq 'method' ? $invocant_name : undef;
    my $first_param       = 1;
    my @params;

    while (length($params) && $params =~ s{\A \s*+ $PARAMETER_SYNTAX }{}x) {
        my %param = %+;
        last if $param{raw_param} !~ /\S/;

        # Special case of literal numeric constant as parameter (e.g. multi func fib(0) { 0 } )...
        if (defined $param{is_num_constant}) {
            $param{type} = 'Num';
            $param{constraint} = "{ \$_ == $param{is_num_constant} }";
        }

        # Special case of literal string constant as parameter (e.g. multi func handle_event('add') {...} )...
        elsif (defined $param{is_str_constant}) {
            $param{type} = 'Str';
            $param{constraint} = "{ \$_ eq $param{is_str_constant} }";
        }

        # Special case of literal regex match as parameter (e.g. multi func # handle_event(/a|b/) {...} )...
        elsif (defined $param{is_regex_constant}) {
            $param{type} = 'Str';
            $param{constraint} = "{ \$_ =~ $param{is_regex_constant} }";
        }

        push @params, \%param;

    }

    # Make an implicit invocant explicit...
    if (!@params && $kind eq 'method') {
        "$invocant:" =~ m{\A \s*+ $PARAMETER_SYNTAX }x;
        push @params, {%+};
    }

    # Extract trailing return type specification...
    if ($params =~ s{ (?&WS) --> (?&WS) (.*+) (?(DEFINE) (?<WS> \s*+ (\# [^\n]*+ \n \s*+ )*+)) }{}xms ) {
        ($return_type, $return_constraint) = split /\bwhere\b/, $1, 2;
    }

    # Anything else in the parameter list is a mistake...
    _error( qq{Invalid parameter specification: $params\n in $kind declaration} )
        if $params =~ /\S/;

    # Convert the parameters into checking code...
    my $code         = q{};
    my $spec         = q{};
    my $nameless_pos = 0;
    my (%param_named, @positional, @named, $slurpy);

    for my $param (@params) {
        $nameless_pos++;

        # Constraints imply an Any type...
        if (defined $param->{constraint} && (!defined $param->{type} || $param->{type} !~ /\S/)) {
            $param->{type} = 'Any';
        }

        # Rectify nameless params...
        if (exists $param->{nameless}) {
            $param->{sigil} ||= '$';
            my $nth = $nameless_pos
                    . ( $nameless_pos =~ /(?<!1)1$/ ? 'st'
                      : $nameless_pos =~ /(?<!1)2$/ ? 'nd'
                      : $nameless_pos =~ /(?<!1)3$/ ? 'rd'
                      :                               'th'
                      );
            $param->{var}      = $param->{sigil} . '__nameless_'.$nth.'_parameter__';
            $param->{namedvar} = $param->{sigil} . ' (unnamed $nth parameter)';
        }

        # "There ken be onla one!" (...parameter of any given name)...
        _error( qq{Can't declare two parameters named $param->{var}\n in specification of $sub_desc})
            if exists $param_named{ $param->{var} };
        $param_named{ $param->{var} }++;

        # Parameters are lexical, so can't be named @_ or $_ or %_...
        _error(
            qq{Can't declare a },
            (exists $param->{name} ? 'named' : exists $param->{slurpy} ? 'slurpy' : 'positional'),
            qq{ parameter named $param->{var}\nin specification of $sub_desc},
        ) if substr($param->{var},1) eq '_' && $param->{namedvar} ne '*@_';

        # Handle implicit invocant specially...
        if ($first_param && $kind eq 'method' && $param->{terminator} ne ':') {
            $code .= _generate_invocant( "$sub_desc", {var=>$invocant_name, sigil=>'$'} );
            $first_param = 0;
        }

        # Handle explicit invocant...
        if ($first_param && $param->{terminator} && $param->{terminator} eq ':') {
            _error( qq{Can't specify invocant ($param->{raw_param}:) for $sub_desc} ) if $kind ne 'method';
            $code .= _generate_invocant( "$sub_desc", $param );
            my $type  = $param->{type} // 'Any';
            my $constraint = $param->{constraint} ? "where => sub $param->{constraint}" : q{};
            $spec .= qq{{type => '$type', $constraint },};
            $first_param = 0;
        }

        # Save a scalar (named or positional) paramater...
        elsif (!exists $param->{slurpy}) {
            if (exists $param->{name}) { push @named,      $param }
            else                       { push @positional, $param }
        }

        # Save the final slurpy array or hash...
        else {
            _error( qq{Can't specify more than one slurpy parameter },
                    qq{($slurpy->{namedvar}, $param->{namedvar})\n},
                    qq{ in specification of $sub_desc}
            ) if defined $slurpy;

            if (exists $param->{name}) {
                _error( qq{Can't specify non-array named slurpy parameter ($param->{namedvar})\n},
                        qq{ in specification of $sub_desc}
                ) if exists $param->{name} && $param->{sigil} ne '@';

                push @named, $param;
            }
            else {
                $slurpy = $param;
            }
        }
    }

    if (@positional) {
        $code .= _generate_positionals( "$sub_desc", @positional );
        for my $param (@positional) {
            my $type  = $param->{type}  // 'Any';

            if    ($param->{sigil} eq '@') { $type = "Array[$type]"; }
            elsif ($param->{sigil} eq '%') { $type = "Hash[$type]";  }

            my $constraint = $param->{constraint} ? "where => sub $param->{constraint}" : q{};

            my $is_optional = exists $param->{default_type} ? 1 : 0;

            $spec .= qq{{optional => $is_optional, type => '$type', $constraint},};
        }
    }
    if (@named) {
        $code .= _generate_nameds( "$sub_desc", @named );
        for my $param (@named) {
            my $type  = $param->{type}  // 'Any';

            if    ($param->{sigil} eq '@') { $type = "Array[$type]"; }
            elsif ($param->{sigil} eq '%') { $type = "Hash[$type]";  }

            my $constraint = $param->{constraint} ? "where => sub $param->{constraint}" : q{};

            my $is_optional = exists $param->{default_type} ? 1 : 0;

            $spec .= qq{{named => '$param->{name}', optional => $is_optional, type => '$type', $constraint},};
        }
    }

    if (defined $slurpy) {
        if ($slurpy->{var} ne '@_') {
            my $constraint = $slurpy->{constraint} ? "where => sub $slurpy->{constraint}" : q{};
            $code .= _generate_slurpies( "$sub_desc", $slurpy );
            $spec .= qq{ {optional => 1, type=>'Slurpy', $constraint} };
        }
    }
    else {
        $code .= qq[Dios::_error q{Unexpected extra argument}.(\@_==1?q{}:q{s}).' ('.join(', ', map { Dios::_perl \$_ } \@_).q{) in call to $sub_desc} if \@_;];
    }

    $return_type = defined $return_type ? qq{q{$return_type}} : "";
    if (defined $return_constraint) {
        $return_type .= qq{, sub $return_constraint };
    }
    return { code => $code, return_type => $return_type, spec => $spec };
}

sub _verify_required_named {
    my ($context, @params) = @_;
    my $code = q{};
    for my $param (@params) {
        next if !$param->{required};
        my $vardesc = quotemeta $param->{namedvar};
        my $argdesc = qq{'$param->{name}' => <} . lc($param->{type}//'value'). q{>};
        $code .= qq[Dios::_error(qq{No argument ($argdesc) found for required named parameter $vardesc\\n]
              .  qq[in call to $context}) if !\$seen{$param->{name}}; ];
    }
    return $code;
}

sub _generate_invocant {
    my ($context, $param) = @_;
    my $code;
    my $vardesc = qq{invocant $param->{var}};

    # Create and unpack corresponding argument...
    $code .= qq{my $param->{var}; };
    $code .= _unpack_code( @{$param}{'sigil','var','name','default','special'}, $vardesc, $context );

    # Install a type check, if necessary...
    if (exists $param->{type}) {
        $code .= _typecheck_code(@{$param}{'sigil','var','type','constraint'}, $vardesc, $context);
    }

    return $code;
}

sub _generate_positionals {
    my ($context, @positionals) = @_;
    my $code;

    for my $param (@positionals) {
        # Create and unpack corresponding argument...
        my $var = $param->{var};
        my $vardesc = $var =~ /^(.)__nameless_(\d++[^\W_]++)_parameter__$/
                        ? "unnamed $2 positional parameter"
                        : "positional parameter $var";
        $code .= qq{my $var; };
        $code .= _unpack_code(
                    @{$param}{'sigil','var','name','default','special'},
                    $vardesc,
                    $context
                 );
        if (exists $param->{name} && exists $param->{default_type}) {
            if ($param->{default_type} eq '//=' && $param->{sigil} eq '$') {
                my $assign_code = _assign_value_code( @{$param}{'sigil','var','special','default'}, q{});
                $code .= qq{ do {$assign_code} if !defined $var; };
            }
            elsif ($param->{default_type} eq '||=') {
                my $assign_code = _assign_value_code( @{$param}{'sigil','var','special','default'}, q{});
                $code .= qq{ do {$assign_code} if !$var; };
            }
        }

        # Install a type check, if necessary...
        next if !exists $param->{type};
        $code .= _typecheck_code(@{$param}{'sigil','var','type','constraint'}, $vardesc, $context);
    }

    return $code;
}

sub _generate_nameds {
    my ($context, @nameds) = @_;
    my $code;

    # Declare all named args...
    $code .= 'my (' . join(',', map { $_->{var} } @nameds) . '); ';

    # Walk the arg list, unpacking them...
    $code .= qq[{ my %seen; while (\@_) { my \$next_key = shift;];

    my $defaults = q{};
    for my $param (@nameds) {
        $code .= qq[ if (\$next_key eq q{$param->{name}}) {];
        my $unpack_code =
            exists $param->{slurpy} ? _unpack_named_slurpy_code(
                                        @{$param}{qw< var sigil name special >},
                                        "slurpy named parameter $param->{namedvar}", $context
                                      )
                                    : _unpack_code(
                                        @{$param}{'sigil','var','name'}, undef, $param->{special},
                                        "named parameter $param->{namedvar}", $context
                                      );
        $code .= qq[$unpack_code next}];

        if (exists $param->{name} && exists $param->{default}) {
            my $assign_code = _assign_value_code( @{$param}{'sigil','var','special','default'}, q{});
            $defaults .= qq{ do {$assign_code} if }
                      .  ( $param->{default_type} eq '//=' ? qq{!defined $param->{var}; }
                         : $param->{default_type} eq '||=' ? qq{!$param->{var}; }
                         :                                   qq{!\$seen{$param->{'name'}}; }
                         );
        }
    }

    my $requireds = _verify_required_named($context, @nameds);

    $code .= qq[unshift \@_, \$next_key; last} $defaults $requireds}];

    for my $param (@nameds) {
        next if !exists $param->{type};

        my $slurpy = exists $param->{slurpy} ? q{slurpy } : q{};
        $code .= _typecheck_code(
                @{$param}{'sigil','var','type','constraint'}, "${slurpy}named parameter $param->{namedvar}", $context
        );
    }

    return $code;
}

my $REFALIASING = q{use experimental 'refaliasing'};

sub _generate_slurpies {
    my ($context, $param) = @_;

    # No slurpy by default...
    return q{} if !defined $param;
    my $special = $param->{special};
    my $code = q{};

    my $vardesc = $param->{var} =~ /^(.)__nameless_.*_parameter__$/
                    ? "nameless slurpy parameter (*$1)"
                    : "slurpy parameter *$param->{var}";

    # Check named slurpies...
    if ($param->{sigil} eq '%') {
        $code .= qq{Dios::_error('Final key ('.Dios::dump(\$_[-1]).qq{) for $vardesc is missing its value\\nin call to $context}) if \@_ % 2;}
    }

    # Create and unpack corresponding argument...
    $code .= !$special                         ? qq{                    my $param->{var} =   }
           : $special eq 'ro'                  ? qq{ Const::Fast::const my $param->{var} =>  }
           : $special eq 'alias' && $] < 5.022 ? qq{ Data::Alias::alias my $param->{var} =   }
           : $special eq 'alias'               ? qq{ $REFALIASING;    \\my $param->{var} =\\ }
           : die "Internal error: unknown special trait: is $special";

    $code .= exists $param->{default} ? qq{ (\@_ ? \@_ : $param->{default}); }
           :                            qq{ \@_; };

    # Install a type check, if necessary...
    if (exists $param->{type}) {
        $code .= _typecheck_code(@{$param}{'sigil','var','type','constraint'}, $vardesc, $context, 'slurpy');
    }

    # Install existence check, if necessary...
    if (exists $param->{required}) {
        my $vardesc = quotemeta $vardesc;
        $code .= qq[Dios::_error qq{Missing argument for required $vardesc\\nin $context} if !\@_;];
    }

    return $code;
}

sub _assign_value_code {
    my ($sigil, $var, $special, $value_source, $check_type) = @_;
    $special //= q{};

    if ($sigil eq '$') {
        return $special eq 'ro'                  ? qq[ Const::Fast::const($var =>   $value_source); ]
             : $special eq 'alias' && $] < 5.022 ? qq[ Data::Alias::alias $var =    $value_source ; ]
             : $special eq 'alias'               ? qq[ $REFALIASING;    \\$var = \\($value_source); ]
             :                                     qq[                    $var =    $value_source ; ]
    }

    # Arrays and hashes, need more type-checking...
    if ($sigil eq '@') {
        return qq[ { my \$next_value = $value_source; ]
             . $check_type
             . ( $special eq 'ro'                  ? qq[ Const::Fast::const($var => \@{\$next_value}); ]
               : $special eq 'alias' && $] < 5.022 ? qq[ Data::Alias::alias $var =  \@{\$next_value} ; ]
               : $special eq 'alias'               ? qq[ $REFALIASING;    \\$var =  \@{\$next_value} ; ]
               :                                     qq[                    $var =  \@{\$next_value} ; ]
               )
             . qq[} ];
    }
    if ($sigil eq '%') {
        return qq[ { my \$next_value = $value_source; ]
             . $check_type
             . ( $special eq 'ro'                  ? qq[ Const::Fast::const($var => \%{\$next_value}); ]
               : $special eq 'alias' && $] < 5.022 ? qq[ Data::Alias::alias $var =  \%{\$next_value} ; ]
               : $special eq 'alias'               ? qq[ $REFALIASING;    \\$var =  \%{\$next_value} ; ]
               :                                     qq[                    $var =  \%{\$next_value} ; ]
               )
             . qq[} ];
    }
}

sub _unpack_code {
    my ($sigil, $var, $name, $default, $special, $vardesc, $context) = @_;
    state $type_of = { '$' => q{}, '@' => 'ARRAY', '%' => 'HASH' };

    # Set up for readonly or aliasing, if specified...
    if ($special) {
        if ($special eq 'ro') {
            _error(q{'is ro' requires the Const::Fast module (which could not be loaded)})
                if !eval { require Const::Fast; 1 };
        }
        elsif ($special eq 'alias' && $] < 5.022) {
            _error(q{'is alias' requires the Data::Alias module (which could not be loaded)})
                if !eval { require Data::Alias; 1 };
        }
    }

    # Set up for default handling, if specified...
    my $value_source = qq{ ( !\@_ ? Dios::_error(q{No argument found for $vardesc in call to $context}) : shift) };
    my $type_check   = qq[ Dios::_error q{Argument for $vardesc is not \L$type_of->{$sigil}\E ref in call to $context} ]
                     . qq[     if ref(\$next_value) ne '$type_of->{$sigil}';];

    if (defined($default)) {
        $default ||= $sigil eq '$' ? 'undef'
                   : $sigil eq '@' ? '[]'
                   :                 '{}';
        my $and_type_test = $sigil eq '$' ? '' : "&& ref(\$_[0]) eq '$type_of->{$sigil}'";
        $value_source = qq{ \@_ $and_type_test ? shift() : $default };
        $type_check   = q{};
    }

    # Named params have to be tracked, if they have defaults...
    my $note_seen
        = $name ? qq{ Dios::_error(q{Unexpected second value (}.Dios::_perl($var).q{) for named '$name' parameter in call to $context}) if \$seen{$name}; \$seen{$name} = 1; }
                : q{};

    # Return the code...
    return _assign_value_code($sigil, $var, $special, $value_source, $type_check)
         . $note_seen;
}

sub _unpack_named_slurpy_code {
    my ($var, $sigil, $name, $special, $vardesc, $context) = @_;
    $special //= q{};

    # Must be able to use the module, if it's required
    if ($special eq 'alias' && $] < 5.022) {
        _error(q{'is alias' requires the Data::Alias module (which could not be loaded)})
            if !eval { require Data::Alias; 1 };
    }

    # Work out how at unpack the arg
    my $unpack_code
        = $special eq 'alias' && $] >= 5.022 ? qq{use experimental 'refaliasing';\\\$${name}[\@$name]=\\shift;}
        : $special eq 'alias'                ? qq{ Data::Alias::alias( \$${name}[\@$name] = shift); }
        :                                      qq{ push $var, shift; };

    return qq{ Dios::_error q{No argument found for $vardesc in call to $context} if !\@_; }
         . $unpack_code;
}

sub _typecheck_code {
    my ($sigil, $var, $type, $constraint, $vardesc, $context, $is_slurpy) = @_;
    $constraint = $constraint ? "sub $constraint" : q{};

    # Provide a human-readble description for any error message...
    $vardesc = qq{q{Value (%s) for $vardesc}};

    if ($sigil eq '$') {
        return qq[{package Dios::Types; validate(q{$type},         $var,$vardesc,$constraint)}];
    }
    if ($sigil eq '@') {
        return qq[{package Dios::Types; validate(q{List[$type]}, \\$var,$vardesc,$constraint)}] if $is_slurpy;
        return qq[{package Dios::Types; validate(q{Array[$type]},\\$var,$vardesc,$constraint)}];
    }
    if ($sigil eq '%') {
        return qq[{package Dios::Types; validate(q{Hash[$type]}, \\$var,$vardesc,$constraint)}];
    }
    die 'Internal error: unable to generate type checking code';
}

sub _perl {
    use Data::Dump 'dump';
    return dump(@_);
}

our @CARP_NOT = 'Keyword::Declare';
sub _error {
    use Carp;
    croak @_;
}

use re 'eval';
my $FIELD_DEFN = qr{
    (?<FIELD_TYPE>
        (?&TYPE_SPEC)
    )? \s*+
    (?<FIELD_SIGIL>
        [\$\@%]
    )
    (?<FIELD_TWIGIL>
        [.!]?
    )
    (?<FIELD_NAME>
        [^\W\d] \w*             # Simple identifier
    )
    (?<FIELD_MANDATORY>
        \s+ is \s+ req(?:uired)?
    )?
    (?:
        \s+ is \s+
        (?<FIELD_RW> r[wo] )
    )?
    (?<FIELD_MANDATORY>         # repeat to allow 'is' options in either order
        \s+ is \s+ req(?:uired)?
    )?
    (?<FIELD_ATTRS>
        \s*+ : \s*+ (?&ATTR)
        (?:
            (?: \s*+ : \s*+ | \s++) (?&ATTR)
        )*+
    )?
    (?<OTHER_ATTRS>
        .*+
    )

    (?(DEFINE)
        (?<TYPE_SPEC>  (?&TYPE_NAME) (?: [&|] (?&TYPE_NAME) )*+ )
        (?<TYPE_NAME>  (?&QUAL_IDENT)  (?&TYPE_PARAM)?+         )
        (?<TYPE_PARAM> \[ (?: [^][]*+ | (?&TYPE_PARAM) )*+ \]   )
        (?<QUAL_IDENT> (?&IDENT) (?: :: (?&IDENT) )*+ )
        (?<IDENT>      [^\W\d] \w*+                   )
        (?<ATTR>       [^\W\d]\w*+  (?! [(] )         )
    )

}xms;

my $SHARED_DEFN = qr{
    (?<SHARED_TYPE>
        (?&TYPE_SPEC)
    )?
    \s*+
    (?<SHARED_SIGIL>
        \$ | \@ | \%
    )
    (?<SHARED_TWIGIL>
        [.!]?
    )
    (?<SHARED_NAME>
        [^\W\d] \w*             # Simple identifier
    )
    (?:
        \s+ is \s+
        (?<SHARED_RW> r[wo] )
    )?
    (?<SHARED_ETC>
        .*
    )

    (?(DEFINE)
        (?<TYPE_SPEC>  (?&TYPE_NAME) (?: [&|] (?&TYPE_NAME) )*+ )
        (?<TYPE_NAME>  (?&QUAL_IDENT)  (?&TYPE_PARAM)?+         )
        (?<TYPE_PARAM> \[ (?: [^][]*+ | (?&TYPE_PARAM) )*+ \]   )
        (?<QUAL_IDENT> (?&IDENT) (?: :: (?&IDENT) )*+ )
        (?<IDENT>      [^\W\d] \w*+                   )
    )

}xms;

my $LEXICAL_DEFN = qr{
    (?<LEXICAL_TYPE>
        (?&TYPE_SPEC)
    )?
    \s*+
    (?<LEXICAL_SIGIL>
        \$ | \@ | \%
    )
    (?<LEXICAL_NAME>
        [^\W\d] \w*             # Simple identifier
    )
    (?<SHARED_ETC>
        .*
    )

    (?(DEFINE)
        (?<TYPE_SPEC>  (?&TYPE_NAME) (?: (?: [&|] | => ) (?&TYPE_NAME) )*+ )
        (?<TYPE_NAME>  (?&QUAL_IDENT)  (?&TYPE_PARAM)?+         )
        (?<TYPE_PARAM> \[ (?: [^][]*+ | (?&TYPE_PARAM) )*+ \]   )
        (?<QUAL_IDENT> (?&IDENT) (?: :: (?&IDENT) )*+ )
        (?<IDENT>      [^\W\d] \w*+                   )
    )

}xms;


# These options can be passed in when importing, to change how accessors are generated...
my %OIO_accessor_keyword = (
    'standard' => { rw => 'Std',    ro => 'StdRO' },
    'unified'  => { rw => 'Acc',    ro => 'Get'   },
    'lvalue'   => { rw => 'Lvalue', ro => 'Get'   },
);
  @OIO_accessor_keyword{qw< std       uni      lval   >}
= @OIO_accessor_keyword{qw< standard  unified  lvalue >};

my %OIO_accessor_generate = (
    'standard' => {
        rw => sub { my ($name, $sigil) = @_;
                    my $var = $sigil.$name;
                    my $unpack = $sigil eq '$' ? 'shift' : '@_';
                    return qq{ sub get_$name { shift; $var }
                               sub set_$name { local \$Carp::CarpLevel = 1;
                                               shift;
                                               $var = $unpack;
                                             };
                             };
              },
        ro => sub { my ($name, $sigil) = @_; my $var = $sigil.$name;
                    return qq{ sub get_$name { shift; $var } };
              },
    },

    'unified' => {
        rw => sub { my ($name, $sigil) = @_;
                    my $var = $sigil.$name;
                    my $unpack = $sigil eq '$' ? 'shift' : '@_';
                    return qq{ sub $name { local \$Carp::CarpLevel = 1;
                                           shift;
                                           if (\@_) {
                                               $var = $unpack;
                                           }
                                           $var
                                         }; };
              },
        ro => sub { my ($name, $sigil) = @_; my $var = $sigil.$name;
                    return qq{ sub $name { shift; $var } };
              },
    },

    'lvalue' => {
        rw => sub { my ($name, $sigil) = @_;
                    my $var = $sigil.$name;
                    return qq{ sub $name :lvalue {
                                    local \$Carp::CarpLevel = 1;
                                    $var
                             }
                           };
              },
        ro => sub { my ($name, $sigil) = @_; my $var = $sigil.$name;
                    return qq{ sub $name         { $var } };
                  },
    },
);
  @OIO_accessor_generate{qw< std       uni      lval   >}
= @OIO_accessor_generate{qw< standard  unified  lvalue >};

# Convert a 'has' to an OIO variable declaration with attributes...
sub _compose_field {
    my ($type, $var, $traits, $handles, $initializer, $constraint) = @_;

    # Normalize constraint...
    $constraint = $constraint ? 'sub ' . substr($constraint, 5) : q{};
    if ($constraint && !defined $type) {
        $type = 'Any';
    }

    # Read-only or readwrite???
    my $rw       = $traits =~ /\brw\b/ ? 'rw' : 'ro';
    my $required = $traits =~ /\breq(?:uired)?\b/;

    # Did the user specify a particular kind of accessor generation???
    my $accessor_type = $^H{'Dios accessor_type'};

    # Unpack the parsed components of the field declaration...
    my ($sigil, $twigil, $name) = $var =~ m{\A ([\$\@%]) ([.!]?+) (\S*+) }xms;

    # Adapt type to sigil...
    my $container_type = ($sigil eq '@') ? "Array[".($type//'Any')."]"
                       : ($sigil eq '%') ?  "Hash[".($type//'Any')."]"
                       :                    $type;

    # Is it type-checked???
    my $TYPE_SETUP = q{};
    my $TYPE_VALIDATOR = q{};
    if ($type) {
        state $validator_num = 0; $validator_num++;
        $TYPE_VALIDATOR = qq[ { no warnings; \$Dios::_internal::attr_validator_$validator_num = Dios::Types::validator_for(q{$container_type}, 'Value (%s) for $sigil$name attribute', $constraint ); } ];
        $TYPE_SETUP = qq[ :Type( sub{ \$Dios::_internal::attr_validator_$validator_num->(shift) }) ];
    }

    # Define accessors...
    my $access = $twigil ne '.' ? q{} : $OIO_accessor_keyword{$accessor_type}{$rw}."(Name=>q{$name}) $TYPE_SETUP";

    # Is it a delegated handler???
    my $delegators = '';
    for my $delegation (split /(?&WS) handles (?&WS) (?(DEFINE) (?<WS> \s*+ (?: \# [^\n]*+ \n \s*+ )*+ ))/x, $handles) {
        next unless $delegation;
        if ($delegation =~ m{^:(.*)<(.*)>$}xms) {
            $delegators .= " :Handles($1-->$2)";
        }
        else {
            $delegators .= " :Handles($delegation)";
        }
    }

    # Is it initialized???
    my $init = qq{:Arg(Name=>q{$name} } . ($required ? q{, Mandatory=>1)} : q{)} );
    my $INIT_FUNC = q{};

    # Ensure array and hash attrs are initialized...
    if ($sigil =~ /[\@%]/ && (!$initializer || $initializer =~ m{\A \s*+ \z}xms)) {
        $initializer = '//=()';
    }

    # Install the initialization code...
    if ($initializer =~ m{\A \s*+ (?<DEFAULT_INIT> // \s*+ )? = (?<INIT_VAL> .*+ ) }xms) {
        my %init_field = %+;
        my $init_val = $init_field{INIT_VAL};

        # Adapt initializer value to sigil...
           if ($sigil eq '@') { $init_val = "[$init_val]"; }
        elsif ($sigil eq '%') { $init_val = "+{$init_val}";  }

        $init = qq{:DEFAULT(___i_n_i_t__${name}___(\$self)) } . ($init_field{DEFAULT_INIT} ? $init : q{});
        $INIT_FUNC = qq{sub ___i_n_i_t__${name}___ { my (\$self) = \@_; $init_val }};
    }
    else {
        $init .= $initializer;
    }

    # Update the attribute setting code...
    if ($sigil eq '$') {
        $^H{'Dios attrs'} .= $] < 5.022 ? qq{alias my \$$name =    \$_Dios__attr_${name}[\${\$_[0]}];}
                                        : qq{   \\ my \$$name = \\ \$_Dios__attr_${name}[\${\$_[0]}];};
    }
    else {
        $^H{'Dios attrs'}
            .= $] < 5.022 ? qq{alias my $sigil$name = $sigil}.qq{{\$_Dios__attr_${name}[\${\$_[0]}]};}
                          : qq{   \\ my $sigil$name =             \$_Dios__attr_${name}[\${\$_[0]}]; };
    }
    # Add type-checking code to alias...
    if ($type) {
        $^H{'Dios attrs'} .= qq{ Dios::Types::_set_var_type(q{$type}, \\$sigil$name, 'Value (%s) for $sigil$name attribute', $constraint ); };
    }

    # Return the converted syntax...
    return qq{ $TYPE_VALIDATOR my \@_Dios__attr_$name : Field $access $delegators $init $TYPE_SETUP; $INIT_FUNC; };
}

# Convert a typed lexical variable...
sub _compose_lexical {
    my ($type, $variable, $constraint) = @_;

    # Normalize constraint...
    $constraint = $constraint ? 'sub ' . substr($constraint, 5) : q{};
    if ($constraint && !defined $type) {
        $type = 'Any';
    }

    # Is it type-checked???
    my $TYPE_SETUP = q{};
    if (defined $type) {
        $TYPE_SETUP  = qq[ Dios::Types::_set_var_type(q{$type}, \\$variable, 'Value (%s) assigned to $variable', $constraint ); ];
    }

    # Return the converted syntax...
    return qq{my $variable; $TYPE_SETUP; $variable = $variable};
}


# Convert a 'shared' to a class attribute...
sub _compose_shared {
    my ($type, $var, $traits, $initializer, $constraint) = @_;

    # Normalize constraint...
    $constraint = $constraint ? 'sub ' . substr($constraint, 5) : q{};
    if ($constraint && !defined $type) {
        $type = 'Any';
    }

    # Did the user specify a particular kind of accessor generation???
    my $accessor_type = $^H{'Dios accessor_type'};

    # Unpack the parsed components of the shared declaration...
    my ($sigil, $twigil, $name) = $var =~ m{\A ([\$\@%]) ([.!]?+) (\S*+) }xms;
    my $rw     = $traits =~ /\brw\b/ ? 'rw' : 'ro';

    # Generate accessor subs...
    my $accessors = $twigil ne '.' ? q{}
                  : $OIO_accessor_generate{$accessor_type}{$rw}->($name, $sigil);

    # Build type checking sub...
    my $type_func = q{};
    if ($type) {
        $type_func = qq[ sub ___t_y_p_e__${name}___ { state \$check = Dios::Types::validator_for(q{$type}, 'Value (%s) for \$$name attribute' ); \$check->($_[0]) } ___t_y_p_e__${name}___($sigil$name); ];
    }
    else {
        $type_func = q{};
    }
    # Is it type-checked???
    my $TYPE_SETUP = q{};
    if ($type) {
        $TYPE_SETUP  = qq[ Dios::Types::_set_var_type(q{$type}, \\$sigil$name, 'Value (%s) for shared $sigil$name attribute', '$sigil', $constraint ); ];
    }

    # Return the converted syntax...
    return qq{my $sigil$name $initializer; $TYPE_SETUP; $accessors};
}



sub _multi_dispatch {
    use Data::Dump 'dump';

    my $subname  = shift;
    my $kind     = shift;
    my @arg_list = @_;

    # Find all possible variants for this call...
    our %multis;
    my @variants = @{ $Dios::multis{$subname} //= [] };

    # But only those in the right hierarchy, if it's a method call
    if ($kind eq 'method') {
        @variants = grep { $arg_list[0]->isa($_->{class}) } @variants;
    }

    # And only those in the right namespace, if it's a function call...
    else {
        my $caller = caller;
        @variants = grep { $_->{class} eq $caller } @variants;
    }

    # Eliminate variants that doen't match the argument list...
    for my $variant (@variants) {
        my $match = eval{ $variant->{validator}(@arg_list) };
        if (defined $match) {
            @{$variant}{ keys %{$match} } = values %{$match};
        }
        else {
            $variant = undef;
        }
    }
    @variants = grep { defined } @variants;

    # If there's only one left, we're done...
    return $variants[0] if @variants == 1;

    # If there isn't one left, we're also done (but not in a good way)...
    return {
        impl => sub { my $args = dump(@arg_list);
                    croak "No suitable '$subname' variant found for call to multi $subname",
                        (($args =~ m{\A \( .* \) \Z}xms) ? $args : qq{($args)});
        },
    } if @variants == 0;

    # There were 2+ left, so pick the one with the most specific signature...
    @variants = Dios::Types::_resolve_signatures($kind, @variants);

    # If there isn't one left, we're also done (but in an even worse way than before)...
    return {
        impl => sub { my $args = dump(@arg_list);
                    croak "Dios: Internal error in dispatch resolution of multi $subname",
                        (($args =~ m{\A \( .* \) \Z}xms) ? $args : qq{($args)});
        },
    } if @variants == 0;

    # Otherwise, return the most specific/earliest...
    return $variants[0];

#====[ NOTE: I still prefer an ambiguity warning, but Perl 6 no longer does that :-( ]=====
#
#    # Otherwise, the call is ambiguous, so report that...
#    return {
#        impl => sub {
#            croak "Ambiguous call to multi '$subname'. Could invoke any of:\n",
#                  map({ my $sig = $_->{sig}; "\t$subname(". join(',',map({$_->{type}} @$sig)) .")\n" } @variants),
#                  "to handle:\n\t$subname(", dump(@arg_list)=~s/^\(|\)$//gr, ")\ncalled";
#        },
#    };
}

keytype ParamList is m{
    \(
        (?:
            (?&Parameter)
            (?:
                (?: (?&PerlOWS) [:,]
                    (?: (?&Parameter) (?&PerlOWS) , )*+
                        (?&Parameter)?+
                )?+
            )?+
        )?+
        (?: (?&PerlOWS) --> [^)]*+ )?+
        (?&PerlOWS)
    \)

    (?(DEFINE)
        (?<Parameter>
            (?&PerlOWS)
            (?:
                # Nameless literal constraint
                (?&PerlNumber) | (?&PerlQuotelikeQ) | (?&PerlMatch)
            |
                (?! , | --> | \) )  # Every component is optional, but there must be at least one

                # TYPE...
                (?: (?&TYPE_SPEC) (?&PerlOWS) )?+

                # NAME...
                (?>
                    : (?&IDENT) \( (?&PerlOWS) [\$\@%] (?&IDENT) (?&PerlOWS) \)
                |
                    :                          [\$\@%] (?&IDENT)
                |
                    \*
                    (?:
                        [\@%] (?&IDENT)?+
                    |
                        : (?&IDENT) \( (?&PerlOWS) \@ (?&IDENT) (?&PerlOWS) \)
                    |
                        :                          \@ (?&IDENT)
                    )
                |
                    [\$\@%] (?&IDENT)?+
                )?+

                # OPTIONAL OR REQUIRED...
                [?!]?+

                # CONSTRAINT...
                (?: (?&PerlOWS) where (?&PerlOWS) (?&PerlBlock) )?+

                # READONLY OR ALIAS...
                (?: (?&PerlOWS) is (?&PerlOWS) (?: ro | alias ) )?+

                # DEFAULT VALUE...
                (?: (?&PerlOWS) (?://|\|\|)? = (?&PerlOWS) (?&PerlConditionalExpression) )?+
            )
        )

        (?<TYPE_SPEC>  (?&TYPE_NAME) (?: [&|] (?&TYPE_NAME) )*+ )
        (?<TYPE_NAME>  (?&QUAL_IDENT)  (?&TYPE_PARAM)?+         )
        (?<TYPE_PARAM> \[ (?: [^][]*+ | (?&TYPE_PARAM) )*+ \]   )
        (?<QUAL_IDENT> (?&IDENT) (?: :: (?&IDENT) )*+           )
        (?<IDENT>      [^\W\d] \w*+                             )
    )
}xms;

sub import {
    my (undef, $opt) = @_;

    # What kind of accessors were requested in this scope???
    $^H{'Dios accessor_type'}
        = $opt->{accessor} // $opt->{accessors} // $opt->{acc} // q{standard};

    # How should the invocants be named in this scope???
    my $invocant_name = $opt->{invocant} // $opt->{inv} // q{$self};
    if ($invocant_name =~ m{\A (\$?+) ([^\W\d]\w*+) \Z}xms) {
        $^H{'Dios invocant_name'} = ($1||'$').$2;
    }
    else {
        _error "Invalid invocant specification: '$invocant_name'\nin 'use Dios' statement";
    }

    # Class definitions are translated to encapsulated packages using OIO...
    keytype Bases is /is (?&PerlNWS) (?&PerlQualifiedIdentifier)/x;
    keyword class (
        QualIdent   $class_name,
        Bases*      @bases,
        Block       $block
    )
    {{{ { package <{$class_name}>; use Object::InsideOut <{ s{^ is (?&WS) (?(DEFINE) (?<WS> \s*+ (?: \# .*+ \n \s*+ )*+ ))}{}x for @bases; (@bases ? qq{qw{@bases}} : q{}) }>; do <{ $block }> } }}}

    # Function definitions are translated to subroutines with extra argument-unpacking code...
    keyword func (
        QualIdent   $sub_name       = '',
        ParamList   $parameter_list = '',
        Attributes  $attrs          = '',
        Block       $block
    )
    {
        # Generate code that unpacks and tests arguments...
        $parameter_list = _translate_parameters($parameter_list, func => "$sub_name");

        # Assemble and return the sub definition...
        if (my $return_type = $parameter_list->{return_type}) {
            qq{sub $sub_name $attrs { $parameter_list->{code} Dios::Types::_validate_return_type [q{$sub_name}, $return_type], \@_, sub $block } };
        }
        else {
            ($sub_name ? "sub $sub_name;" : q{} )
            . qq{sub $sub_name $attrs { $parameter_list->{code} do $block } };
        }
    }

    # Multi definitions are translated to subroutines with extra argument-unpacking code...
    keyword multi (
        /method|func/  $type           = 'func',
        QualIdent      $sub_name       = '',
        ParamList      $parameter_list = '',
        Attributes     $attrs          = '',
        Block          $block
    )
    {
        # Generate code that unpacks and tests arguments...
        $parameter_list = _translate_parameters($parameter_list, $type => "$sub_name");
        my $parameter_types = $parameter_list->{spec};

        # Assemble and return the method definition...
        my $code = qq{ BEGIN { *$sub_name = sub { my \$best_variant = Dios::_multi_dispatch('$sub_name', '$type', \@_); \@_ = \@{\$best_variant->{args}//[]}; goto &{\$best_variant->{impl}}; } if ! *${sub_name}{CODE}; } };

        my $multiname = sprintf 'DIOS_multi_%010d', ++$Dios::multinum;

        # Assemble and return the sub definition...
        if (my $return_type = $parameter_list->{return_type}) {
            $code .= qq{sub $multiname; sub $multiname $attrs { local *$multiname = '$sub_name'; $parameter_list->{code}; return { args => \\\@_, impl => sub { local *__ANON__ = '$sub_name'; Dios::Types::_validate_return_type [q{$sub_name}, $return_type], \@_, sub $block } } } };
        }
        else {
            $block = substr($block,1,-1);
            $code .= qq{sub $multiname; sub $multiname $attrs { local *$multiname = '$sub_name'; $parameter_list->{code}; return { args => \\\@_, impl => sub { local *__ANON__ = '$sub_name'; $block } } } };
        }
        $code .= qq{BEGIN{ push \@{ \$Dios::multis{q{$sub_name}} }, { sig => [$parameter_types], class => __PACKAGE__, validator => \\&$multiname }; }};

        return $code;
    }

    # Method definitions are translated to subroutines with extra invocant-and-argument-unpacking code...
    keyword method (
        QualIdent   $sub_name       = '',
        ParamList   $parameter_list = '',
        Attributes  $attrs          = '',
        Block       $block
    )
    {
        # Which kind of aliasing do we need (to create local vars bound to the object's fields)???
        my $use_aliasing = $] < 5.022 ? q{use Data::Alias} : q{use experimental 'refaliasing'};
        my $attr_binding = $^H{'Dios attrs'} ? "$use_aliasing; $^H{'Dios attrs'}" : q{};

        # Generate code that unpacks and tests arguments...
        $parameter_list = _translate_parameters($parameter_list, method => "$sub_name");

        # Assemble and return the method definition...
        ($sub_name ? "sub $sub_name;" : q{} )
        . qq{sub $sub_name $attrs { $attr_binding { $parameter_list->{code}; do $block } } };
    }

    # Submethod definitions are translated like methods, but with special re-routing...
    keyword submethod (
        QualIdent  $sub_name       = '',
        ParamList  $parameter_list = '',
        Attributes $attrs          = '',
        Block      $block
    )
    {
        # Which kind of aliasing do we need (to create local vars bound to the object's fields)???
        my $use_aliasing = $] < 5.022 ? q{use Data::Alias} : q{use experimental 'refaliasing'};
        my $attr_binding = $^H{'Dios attrs'} ? "$use_aliasing; $^H{'Dios attrs'}" : q{};

        # Handle any special submethod names...
        my $init_args = q{};
        if ($sub_name eq 'BUILD') {
            # Extract named args for :InitArgs hash (TODO: this should pull out type/required info too)...
            my @param_names = $parameter_list =~ m{ : [\$\@%]?+ (\w++) }gxms;

            # Tell OIO about this constructor args...
            $init_args = qq{ BEGIN{ my %$sub_name :InitArgs = map { \$_ => '' } qw{@param_names}; } };

            # Mark the sub as an initializer
            $attrs .= ' :Private :Init';

            # Repack the arguments from ($self, {attr=>val, et=>cetera}) to ($self, attr=>val, et=>cetera)...
            $attr_binding = q{@_ = ($_[0], %{$_[1]});} . $attr_binding;
        }
        elsif ($sub_name eq 'DESTROY') {
            # Parameter list will never be satisfied (which breaks cleanup), so don't allow it at all...
            return q{die 'submethod DESTROY cannot have a parameter list';}
                if $parameter_list && $parameter_list !~ /^\(\s*+\)$/;

            # Mark it as a destructor...
            $attrs .= ' :Private :Destroy';

            # Rename it so as not to clash with OIO's DESTROY...
            $sub_name = '___DESTROY___';
        }
        else {
            $attr_binding = qq{ if ((ref(\$_[0])||\$_[0]) ne __PACKAGE__) { return \$_[0]->SUPER::$sub_name(\@_[1..\$#_]); } } . $attr_binding;
        }

        # Generate the code to unpack and test arguments...
        $parameter_list = _translate_parameters($parameter_list, method => "$sub_name");

        # Assemble and return the method definition...
        ($sub_name ? "sub $sub_name;" : q{} )
        . qq{$init_args sub $sub_name $attrs { $attr_binding $parameter_list->{code}; do $block } };
    }

    # Components of variable declaration...
    keytype TypeSpec   is m{ (?&TypeSpec)
                             (?(DEFINE)
                                 (?<TypeSpec>
                                     (?&TypeName) (?: (?: [&|] | => ) (?&TypeName) )*+
                                 )
                                 (?<TypeSpecSpacey>
                                     \s* (?&TypeName) (?: \s* (?: [&|] | => ) \s* (?&TypeName) )*+ \s*
                                 )
                                 (?<TypeName>
                                     Match \[ [^]]*+ \]
                                 |
                                     (?&PerlIdentifier) \[ (?&TypeSpecSpacey) \]
                                 |
                                     (?&PerlQualifiedIdentifier)
                                 )
                             )
                          }x;
    keytype Var        is / [\$\@%] [.!]?+ (?&PerlIdentifier) /x;
    keytype Traits     is / (?: (?&PerlOWS) is (?&PerlOWS) (?: ro | rw | req(?:uired)? ) )++ /x;
    keytype Handles    is / (?: (?&PerlOWS) handles (?&PerlOWS)
                                (?: (?&PerlIdentifier) | :(?&PerlIdentifier)<(?&PerlIdentifier)> )
                            )++ /x;
    keytype Init       is m{ (?: // )?+ = (?&PerlOWS) (?&PerlExpression) }x;
    keytype Constraint is m{ where (?&PerlOWS) (?&PerlBlock) }x;

    # An attribute definition is translated into an array with a :Field attribute...
    keyword has (
        TypeSpec    $type       = '',
        Var         $variable,
        Constraint  $constraint = '',
        Traits      $traits     = '',
        Handles     $handles    = '',
        Init        $init       = '',
    ) {
        _compose_field($type, $variable, $traits, $handles, $init, $constraint)
    }

    keytype ReadTraits   is / (?&PerlOWS) is (?&PerlOWS) (?: ro | rw ) /x;

    # An attribute definition is translated into an my var with extra code for accessors...
    keyword shared (
        TypeSpec    $type       = '',
        Var         $variable,
        Constraint  $constraint = '',
        ReadTraits  $traits     = '',
        Init        $init       = '',
    ) {
        _compose_shared($type, $variable, $traits, $init, $constraint)
    }

    # An lexical variable definition is translated into a typed lexical...
    keyword lex (TypeSpec? $type, Var $variable, Constraint? $constraint) {
        _compose_lexical($type, $variable, $constraint)
    }


    # Subtypes are handled by Dios::Types...
    keyword subtype {{{ use Dios::Types; subtype }}}

    # Tail recursion is handled as in Perl 6...
    keyword callwith () {{{ goto &{+do{no strict 'refs'; \&{(caller 0)[3]} }} for 1, @_ = grep 1, }}}
    keyword callsame () {{{ goto &{+do{no strict 'refs'; \&{(caller 0)[3]} }}                     }}}

}

1; # Magic true value required at end of module

__END__

=head1 NAME

Dios - Declarative Inside-Out Syntax


=head1 VERSION

This document describes Dios version 0.002010


=head1 SYNOPSIS

    use Dios;

    # Declare a derived class...
    class Identity is Trackable {

        # All instances share these variables...
        shared Num %!allocated_IDs;   # Private and readonly
        shared Num $.prev_ID is rw;   # Public and read/write

        # Declare a function (no invocant)...
        func _allocate_ID() {
            while (1) {
                # Declare a typed lexical variable...
                lex Num $ID = rand;

                return $prev_ID =$ID if !$allocated_IDs{$ID}++;
            }
        }

        # Each instance has its own copy of each of these attributes...
        has Num $.ID     = _allocate_ID();  # Initialized by function call
        has Str $.name //= '<anonymous>';   # Initialized by ctor (with default)

        has Passwd $!passwd;                # Private, initialized by ctor

        # Methods have $self invocants, and can access attributes directly...
        method identify (Str $pwd --> Str) {
            return "$name [$ID]" if $pwd eq $passwd;
        }

        # Destructor (submethods are class-specific, not inheritable)...
        submethod DESTROY {
            say "Bye, $name!";
        }
    }


=head1 DESCRIPTION

This module provides a set of compile-time keywords that simplify the
declaration of encapsulated classes using fieldhashes and the "inside
out" technique, as well as subroutines with full parameter
specifications.

The encapsulation, constructor/initialization, destructor, and accessor
generation behaviours are all autogenerated. Type checking is provided
by the Dios::Types module. Parameter list features are similar to those
provided by Method::Signature or Kavorka.

As far as possible, the declaration syntax (and semantics) provided by
Dios aim to mimic that of Perl 6, except where intrinsic differences
between Perl 5 and Perl 6 make that impractical, in which cases the
module attempts to provide a replacement syntax (or semantics) that is
likely to be unsurprising to experienced Perl 5 programmers.


=head1 INTERFACE

=head2 Declaring classes

The module provides a C<class> keyword for declaring classes.
The class name can be qualified or unqualified:

    use Dios;

    class Transaction::Source {
        # class definition here
    }

    class Account {
        # class definition here
    }


=head3 Specifying inheritance relationships

To specify a base class, add the C<is> keyword after the classname:

    class Account::Personal is Account {
        # class definition here
    }

You can specify multiple bases classes multiple C<is> keywords:

    class Account::Personal is Account is Transaction::Source {
        # class definition here
    }


=head2 Declaring object attributes

Within a class, attributes (a.k.a. fields or data members) are declared
with the C<has> keyword:

    class Account {

        has $.name is rw //= '<unnamed>';
        has $.ID   is ro   = gen_unique_ID();
        has $!pwd;
        has @.history;
        has %!signatories;

        # etc.
    }


=head3 Attribute declaration syntax

The full syntax for an attribute declaration is:

        has  <TYPE> [$@%]  [!.]  <NAME>  [is [rw|ro|req]]  [handles <NAME>]  [//=|=] <EXPR>
             ...... .....  ....  ......   ..............    ..............    ... .  ......
                :     :     :      :            :                 :            :  :     :
    Type [opt]..:     :     :      :            :                 :            :  :     :
    Sigil.............:     :      :            :                 :            :  :     :
    Public/private..........:      :            :                 :            :  :     :
    Attribute name.................:            :                 :            :  :     :
    Readonly/read-write/required traits [opt]...:                 :            :  :     :
    Delegation handlers [opt].....................................:            :  :     :
    Default initialized [opt]..................................................:  :     :
    Always initialized [opt]......................................................:     :
    Initialization value [opt]..........................................................:


=head4 Typed attributes

Attributes can be given a type, by specifying the typename immediately
after the C<has> keyword:

        has  Str     $.name;
        has  Int     $.ID;
        has  PwdObj  $!pwd;
        has  Str     @.history;
        has  Access  %!signatories;

You can use any type supported by the L<Dios::Types> module.
Untyped attributes can store any Perl scalar value
(i.e. their type is C<Any>).

As in Perl 6, the type specified for an array or hash attribute applies
to each value in the container.

Attribute types are checked on initialization, on direct assignment, and
when their write accessor (if any) is called.


=head4 Public vs private attributes

An attribute specification can autogenerate read/write or read-only
accessor methods (i.e. "getters" and "setters"),
if you place a C<.> after the variable's C<$>:

    has $.name;    # Generate accessor methods

Such attributes are referred to as being "public".

If you don't want any accessors generated, use a C<!> instead:

    has $!password;    # Doesn't generate accessor methods (i.e. private)

Such attributes are referred to as being "private".


=head4 Read-only vs read-write attributes

By default, a public attribute autogenerates only a read-accessor (a
"getter" method that returns its current value). To request that full
read-write accessors ("getter" and "setter") be generated,
specify C<is rw> after the attribute name:

    has $.name;          # Autogenerates only getter method
    has $.addr is rw;    # Autogenerates both getter and setter methods

You can also indicate explicitly that you only want a getter:

    has $.name is ro;    # Autogenerates only getter method


=head4 Delegation attributes

You can specify that an attribute is a handler for specific methods,
using the C<handles> trait, which must come after any C<is> traits.

To specify that an attribute handles a single method:

    has $.timestamp is ro handles date;

Now, any call to C<< ->date >> on the surrounding object will be
converted to a call to C<< $timestamp->date >>

To specify that an attribute handles a single method, but dispatches
it under a different name:

    has $.timestamp is ro handles :get_date<date>;

Now, any call to C<< ->get_date >> on the surrounding object will be
converted to a call to C<< $timestamp->date >>

To specify that an attribute will handle any method of a single class:

    has $.timestamp is ro handles Date::Stamp;

Now, any call on the surrounding object to any method provided
by the class C<Date::Stamp> will be converted to a call to the same
method on C<$timestamp>. For example, if C<Date::Stamp> provides
methods C<date>, C<time>, and C<raw>, then any call to any of those
methods on the surrounding object will be passed directly to the
obkect in C<$timestamp>.

An attribute may specify as many C<handles> traits as it needs.




=head4 Get/set vs unified vs lvalue accessors

The accessor generator can build different styles of accessors (just as
Object::Insideout can).

By default, accessors are generated in the "STD" style:

    has $.name is ro;    # print $obj->get_name();
    has $.addr is rw;    # print $obj->get_addr(); $obj->set_addr($new_addr);

However, if the module is loaded with a named "accessor" argument,
all subsequent attribute definitions in the current lexical scope
are generated with the specified style.

For example, to request a single getter/setter accessor:

    use Dios {accessors => 'unified'};

    has $.name is ro;    # print $obj->name();
    has $.addr is rw;    # print $obj->addr(); $obj->addr($new_addr);

or to request a single lvalue accessor:

    use Dios {accessors => 'lvalue'};

    has $.name is ro;    # print $obj->name();
    has $.addr is rw;    # print $obj->addr(); $obj->addr = $new_addr;

If you want to be explicit about using "STD" style accessors, you can also
write:

    use Dios {accessors => 'standard'};


=head4 Required attributes

Attributes are initialized using the value of the corresponding named
argument passed to their object's constructor.

Normally, this initialization is optional: there is no necessity to
provide a named initializer argument for an attribute, and no warning or
error if none is provided.

If you want to I<require> that the appropriate named initializer
value must be present, add C<is req> or C<is required> after the
attribute name:

    has $.name is req;   # Must provide a 'name' argument to ctor
    has $.addr;          # May provide an 'addr' argument, but not necessary

If an initializer value isn't provided for a named argument, the class's
constructor will throw an exception.


=head4 Initializing attributes

Attributes are usually initialized from the arguments passed to their object's
constructor, but you can also provide a default initialization to be used if
no initial value is passed, by specifying a trailing C<//=> assignment:

    has $.addr //= '<No known address>';

The expression assigned can be as complex as you wish, and can also
refer directly to the object being initialized as C<$self>:

    state $AUTOCHECK;

    has $.addr //= $AUTOCHECK ? $self->check_addr() : '<No known address>';

Note, however that other attributes cannot be directly referred to in an
initialization (as they are not guaranteed to have been defined within
the object at that point).


=head2 Declaring class attributes

Attributes declared with a C<has> are per-object. That is, every object has its
own version of the attribute variable, distinct from every other object's version
of that attribute.

However, it is also possible to declare one or more "class attributes", which are
shared by every object of the class. This is done by declaring the attribute with
the keyword C<shared> instead of C<has>:

    class Account {

        shared $.status;   # All account objects share this $status variable

        has $.name;        # Each account object has its own $name variable

    }

Shared attributes have the following declaration syntax:

    shared  [<TYPE>]  [$@%]  [!.]  <NAME>  [is [rw|ro]]  [= <EXPR>] ;
            ........  .....  ....  ......  ............  ..........
                :       :      :      :          :            :
    Type [opt]..:       :      :      :          :            :
    Sigil...............:      :      :          :            :
    Public/private.............:      :          :            :
    Attribute name....................:          :            :
    Readonly/read-write [opt]....................:            :
    Initialization [opt]......................................:

That is, they can have most of the same behaviours as per-object C<has>
attributes, except that they are never initialized from the constructor
arguments, so they can't be marked C<is required>, and any
initialization must be via simple assignment (C<=>), not default
assignment (C<//=>).

Like C<has> attributes, C<shared> attributes can be declared as scalars,
arrays, or hashes. For example:

    class Account {

        shared %is_active; # Track active objects...

        submethod BUILD    { $is_active{$self} = 1;    }
        submethod DESTROY  { delete $is_active{$self}; }
    }


=head2 Declaring typed lexicals

Dios also supports typed lexical variables, not associated with
any class or object, using the keyword C<lex>.

Unlike variables declared with a <my>, variables declared with C<lex>
may be given a type, which is thereafter enforced on any subsequent
assignment. For example:

    lex Str        $name;
    lex Num        @scores;
    lex Array[Int] %rankings;

As with C<has> and C<shared> variables, the type of a C<lex> array or
hash constrains the values of that container. So, in the preceding
example, the C<@scores> array can only store numbers, and each value in
the C<%rankings> hash must be a reference to an array whose values must
be integers.

C<lex> variables can be declared in any scope: in methods or subroutines,
in the class block itself, or in the general code. In all other respects
apart from type-checking, they are identical to C<my> variables.


=head2 Declaring methods and subroutines

Dios provides two keywords, C<method> and C<func>, with which
you can declare methods and functions. Methods can only be declared
inside a Dios C<class> definition, but functions can be declared
in any scope.

A second difference is that methods automatically
have their invocant unpacked, either implicitly into C<$self>,
or explicitly into a defined invocant parameter.

A third difference is that every method in Dios gets direct private
access to its attribute variables. That is: you can refer to an
attribute from within a method simply by using its name without the C<.>
or C<!> (see the use of direct lookups on %is_active in the Account
class example at the end of the previous section).

Both methods and functions may be declared with a parameter list,
as described in the subsequent subsections. If no parameter list
is specified, it is treated as an empty parameter list (i.e. as
declaring that the method or subroutine takes no arguments).


=head3 Parameter list syntax

A function parameter list consists of zero or more comma-separated
parameter specifications in parentheses, optionally followed by a
return type specification:

    func NAME ( PARAM, PARAM, PARAM, ... --> RETTYPE ) { BODY }

A method parameter list consists of an optional invocant specification,
followed by the same zero or more parameter specifications:

    method NAME ( INVOCANT: PARAM, PARAM, PARAM, ... --> RETTYPE ) { BODY }
    method NAME (           PARAM, PARAM, PARAM, ... --> RETTYPE ) { BODY }

As a special case, both methods and functions can be specified
with a single C<( *@_ )> parameter (note: B<not> C<( @_ )>),
in which case methods still unpack their invocant, but otherwise no
parameter processing is performed and the arguments remain in C<@_>.


=head4 Invocant parameters

By default, methods have their invocant object unpacked into a
parameter named C<$self>. If you prefer some other name, you can
specify the invocant parameter explicitly, followed by a colon:

    method ($invocant: $other, $args, $here) {...}
    method (    $this: $other, $args, $here) {...}
    method (      $me: $other, $args, $here) {...}

Note that the colon is essential:

    method ($this: $that) {...}  # Invocant is $this, plus one arg

    method ($this, $that) {...}  # Invocant is $self, plus two args

Like all other kinds of parameters, explicit invocants can be specified
with any type supported by L<Dios::Types>. Generally this makes little
sense unless that type is the name of the current class, or one of its
base classes, in which case it is merely redundant.

However, the mechanism does have one important use: to specify a
class-only or object-only method:

    # A method callable only on the class itself
    method list_active (Class $self:) {...}

    # A method callable only on instances of the class
    method make_active (Obj $self:) {...}


=head4 Positional parameters

A positional parameter specifies that there must be a corresponding
single argument in the argument list, which is then assigned to the
parameter variable.

Positional parameters may be specified as scalars:

    func add_soldier ($name, $rank, $serial_num) {...}

in which case the corresponding argument may be any scalar value:

    add_soldier('George', 'General', 123456);

Positional parameters may also be specified as arrays or hashes, in
which case the corresponding argument must be a reference of the same
kind. The contents of the referenced container are (shallow) copied into
the array or hash parameter variable.

For example:

    func show_targets (%hash, @targets) {
        for my $target (@targets) {
            for my $key (keys %hash) {
                say "$key: $hash{$key}" if $key ~~ $target;
            }
        }
    }

could be called like so:

    show_targets( \%records, [qr/mad/, 'bad', \&dangerous] );


Positional parameters are required by default, so passing the wrong
number of positional arguments (either too few or too many) normally
produces a run-time exception. See L<Optional and required parameters>
to change that behaviour.

If the parameters are specified with types, the values must be compatible
as well. You can mix typed and untyped parameters in the same specification:

    func dump_to (IO $fh, $msg, Obj %data, Bool $sort) {
        say {$fh} $msg;
        for my $key ($sort ? sort keys %data : keys %data) {
            say {$fh} "$key => $data{$key}";
        }
    }

As in L<Dios::Types>, a type applied to an array or a hash applies to the
individual values stored in that container. So, in the previous example,
every value in C<%data> must be an object.


=head4 Nameless positional parameters

If a positional parameter will not actually be used inside its
subroutine or method, but must still be present in the parameter list
(e.g. for backwards compability, or as part of a multimethod
signature), then the parameter can be specified by just a sigil without
a following name.

For example instead of:

    func extract_keys( Str $text, Hash $options ) {
        return [ $text =~ m{$KEY_PAT}g ];
    }

you can omit the name of the unused options variable:

    func extract_keys( Str $text, Hash $ ) {
        return [ $text =~ m{$KEY_PAT}g ];
    }

Moreover, if the nameless parameter variable has a type specifier
(as in the preceding example), then you can omit the sigil as well:

    func extract_keys( Str $text, Hash ) {
        return [ $text =~ m{$KEY_PAT}g ];
    }

Note that this implies that an untyped nameless parameter can be
specified either by just its sigil, or by just the generic type C<Any>:

    func extract_keys( $text, $ ) {
        return [ $text =~ m{$KEY_PAT}g ];
    }

    func extract_keys( $text, Any ) {
        return [ $text =~ m{$KEY_PAT}g ];
    }


=head4 Named parameters

You can also specify parameters that locate their corresponding arguments
by name, rather than by position...by prefixing the parameter variable with
a colon, like so:

    func add_soldier (:$name, :$rank, :$serial_num) {...}

In this version, the corresponding arguments must be labelled with the
names of the parameters, but may be passed in any order:

    add_soldier(serial_num => 123456, name => 'George', rank => 'General');

Each label tells the method or subroutine which parameter the following
argument should be assigned to.

You can specify both positional and named parameters in the same signature:

    func add_soldier ($serial_num, :$name, :$rank) {...}

and in any order:

    func add_soldier (:$name, $serial_num, :$rank) {...}
    func add_soldier (:$rank, :$name, $serial_num) {...}

but the positional arguments B<must> be passed to the call first:

    add_soldier(123456, rank => 'General', name => 'George');

although the named arguments can still be passed in any order after
the final positional.

Named parameters can also have types specified, if you wish,
in which case the type comes before the colon:

    func add_soldier ($serial_num, Str :$name, Str :$rank) {...}

You can also specify a named parameter whose label is different from
its variable name. This is achieved by specifying the label immediately
after the colon (with no sigil), and then the variable (with its sigil)
inside a pair of parentheses immediately thereafter:

    func add_soldier (:$name, :designation($rank), :ID($serial_num)) {...}

This mechanism allows you to use labels that make sense in
the call, but variable names that make sense in the body. For example,
now the function would be called like so:

    add_soldier(ID => 123456, designation => 'General', name => 'George');

Named parameters can be any kind of variable (scalar, array, or hash).
As with positional parameters, non-scalar parameters expect a reference
of the appropriate kind, whose contents they copy. For example:

    func show_targets (:@targets, :from(%hash),) {
        for my $target (@targets) {
            for my $key (keys %hash) {
                say "$key: $hash{$key}" if $key ~~ $target;
            }
        }
    }

which would then be called like so:

    show_targets( from => \%records, targets => [qr/mad/, 'bad', \&dangerous] );

Note that, unlike positional parameters, named parameters are optional
by default (but see L<Optional and required parameters> to change that).


=head4 Slurpy parameters

Both named and positional parameters are intrinsically "one-to-one":
for every parameter, the method or subroutine expects one argument.
Even array or hash parameters expect exactly one reference.

But often you need to be able to create methods or functions that take
an arbitrary number of arguments. So Dios allows you to specify one
extra parameter that is specially marked as being "slurpy", and which
therefore collects and stores all remaining arguments in the argument
list.

To specify a slurpy parameter, you prefix an array parameter with an
asterisk (C<*>), like so:

    func dump_all (*@values) {
        for my $value (@values) {
            dump_value($value);
        }
    }

    # and later...

    dump_all(1, 'two', [3..4], 'etc');

Alternatively, you can specify the slurpy parameter as a hash, in which case
it the list of arguments is assigned to the hash (and should therefore be
a sequence of key/value pairs). For example:

    func dump_all (*%values) {
        for my $key (%values) {
            dump_value($values{$key});
        }
    }

...which would be called like so:

    dump_all(seq=>1, name=>'two', range=>[3..4], etc=>'etc');

and would collect all four labelled arguments as key/value pairs
in C<%value>.

Either kind of slurpy parameter can be specified along with other
parameters. For example:

    func dump_all ($msg, :$sorted, *@values) {
        say $msg;
        for my $value ($sorted ? sort @values : @values) {
            dump_value($value);
        }
    }

When called, the positional arguments are assigned to the positional
parameters first, then any labeled arguments are assigned to the
corresponding named parameters, and finally anything left in the
argument list is given to the slurpy parameter:

    dump_all('Look at these', sorted=>1,  1, 'two', [3..4], 'etc');
    #         \___________/           V    \___________________/
    #             $msg             $sorted        @values


Slurpy parameters can be specified with a type specifier, in which case
each value that they accumulate must be consistent with that type. For
example, if you're doing a numeric sort, you probably want to ensure
that all the values being (optionally) sorted are numbers:

    func dump_all ($msg, :$sorted, Num *@values) {
        say $msg;
        for my $value ($sorted ? sort {$a<=>$b} @values : @values) {
            dump_value($value);
        }
    }


=head4 Named slurpy array parameters

Another option for passing labelled arguments to a subroutine is the
named slurpy array parameter.

Unlike a named parameter (which collects just a single labelled value
from the argument list), or a slurpy hash parameter (which collects
every labelled value from the argument list), a named slurpy array
parameter collects every value I<with a given label> from the argument
list.

Also unlike a regular slurpy parameter, you may specify two or more
named slurpy parameters (as well as one regular slurpy, if you wish).

This allows you to pass multiple separate labelled values and have them
collected by name:

    func process_caprinae ( *:@sheep, *:goat(@goats) ) {
        shear(@sheep);
         milk(@goats);
    }

Such a function might be called like this:

    process_caprinae(
        sheep => 'shawn',
         goat => 'billy',
        sheep => 'sarah',
        sheep => 'simon',
         goat => 'nanny',
    );

In other words, you can use named slurpy arrays to partition a sequence
of labelled arguments into two or more coherent sets.

Named slurpy array parameters may be given a type, in which case every
labelled argument value appended to the parameter array must be
compatible with the specified type.

Note that named slurpy parameters can only be declared as arrays, since
neither hashes nor scalars make much sense in that context.


=head4 Constrained parameters

In addition to specifying any Dios::Types-supported type for any kind of
parameter, you can also specify a constraint on the parameter, by adding
a C<where> block. For example:

    func save (
        $dataset   where { length > 0 },
        $filename  where { /\.\w{3}$/ },
       :$checksum  where { $checksum->valid },
       *@infolist  where { @infolist <= 100 },
    ) {...}

A C<where> block adds a constraint check to the validation of the
variable's type, even if the type is unspecified (i.e. it's the
default C<Any>).

The block is treated exactly like the constraint argument to
C<Dios::Types::validate()> (see L<Dios::Types> for details).

So in the previous example, any call to C<save> requires that:

=over

=item *

The value passed to the positional C<$dataset> parameter must be
(convertible to) a non-empty string,

=item *

The value passed to the positional C<filename> parameter must be
(convertible to) a string that ends in a dot and three characters,

=item *

The object passed to the named C<$checksum> parameter must return
true when its C<valid()> method is invoked, and

=item *

The number of trailing arguments collected by the slurpy C<@infolist>
parameter must no more than 100.

=back

As the previous example indicates, C<where> blocks can refer to the
parameter variable they are checking either by its name or as C<$_>.
They can also refer to any other parameter declared before it in the
parameter list. For example:

    func set_range (Num $min, Num $max where {$min <= $max}) {...}


=head4 Literal constraints

As a special case of this general parameter constraint mechanism, if the
constraint is to match against a literal string or numeric value or a
regular expression, then the constraint can be specified by just the
literal value.

Note that specifying constrained parameters via constants and patterns
is almost only ever useful for multifuncs and multimethods.

For example:

    multi factorial ($n where { $n == 0 }) { 1 }
    multi factorial ($n)                   { $n * factorial($n-1) }

could be written as just:

    multi factorial (0)  { 1 }
    multi factorial ($n) { $n * factorial($n-1) }

Likewise:

    multi handle_cmd ($cmd where { $cmd eq 'insert'  }, $data) {...}
    multi handle_cmd ($cmd where { $cmd eq 'delete'  }, $data) {...}
    multi handle_cmd ($cmd where { $cmd eq 'replace' }, $data) {...}

could be simplified to:

    multi handle_cmd ('insert',  $data) {...}
    multi handle_cmd ('delete',  $data) {...}
    multi handle_cmd ('replace', $data) {...}

And:

    multi handle_cmd ($cmd where { $cmd =~  /^(quit|exit)$/i  },  $data) {...}
    multi handle_cmd ($cmd where { $cmd =~ m{ optimi[zs]e }ix }, $data) {...}

could be specified as just:

    multi handle_cmd (  /^(quit|exit)$/i,  $data) {...}
    multi handle_cmd ( m{ optimi[zs]e }ix, $data) {...}

At present literal parameters can only be numbers, single-quoted
strings, or regexes without variable interpolations.


=head4 Optional and required parameters

By default, all positional parameters declared in a parameter list
are "required". That is, an argument must be passed for each declared
positional parameter.

All other kinds of parameter (named, or slurpy, or named slurpy) are
optional by default. That is, an argument may be passed for them, but
the call will still proceed if one isn't.

You may also specify optional positional parameters, by declaring them
with a C<?> immediately after the variable name. For example:

    func add_soldier ($serial_num, $name, $rank?, $unit?) {...}

Now the function can take either two, three, or four arguments,
with the first two always being assigned to C<$serial_num> and C<$name>.
If a third argument is passed, it is assigned to C<$rank>. If a fourth
argument is given, it's assigned to C<$unit>.

You can also specify any other kind of (usually optional) parameter as
being required, by appending a C<!> to its variable name. For example:

    func dump_all ($msg, :$sorted!, *@values!) {...}

Now, in addition to the positional C<$msg> parameter being required,
a labelled argument must also be provided for the named C<$sorted>
parameter, and there must also be at least one argument for the
slurpy C<@values> parameter to be assigned as well.

The C<?> and C<!> modifiers can be applied to B<any> parameter, even
if the modifier doesn't change the parameter's usual "required-ness".
For example:

    func add_soldier ($serial_num!, $name!, :$rank?, :$unit?) {...}


=head4 Typed and constrained optional parameters

If no argument is passed for an optional parameter, then the
parameter will retain its uninitialized value (i.e. C<undef> for
scalars, empty for arrays and hashes).

If the parameter has a type or a C<where> constraint, then that type
or constraint is still applied to the parameter, and may not be satisfied
by the uninitialized value.  For example:

    func dump_data(
        Int  $offset?,
        Str :$msg,
        Any *@data where { @data > 2 }
    ) {...}

    # and later...

    dump_data();
    # Error: Value (undef) for positional parameter $offset is not of type Int

    dump_data(1..10);
    # Error: Value (undef) for named parameter :$msg is not of type Str

    dump_data(-1, msg=>'results:');
    # Error: Value ([]) for slurpy parameter @data
    #        did not satisfy the constraint: { @data > 2 }

The solution is either to ensure the type or constraint can accept the
uninitialized value as well:

    func dump_data(
        Int|Undef  $offset,
        Str|Undef :$msg,
        Any       *@data where { !@data || @data > 2 }
    ) {...}

or else to give the optional parameter a type-compatible default value.


=head4 Optional parameters with default values

You can specify a value that an optional parameter should be initialized
to, if no argument is passed for it. Or if the argument passed for it is
undefined. Or false.

To provide a default value if an argument is missing (i.e. not passed in
at all), append an C<=> followed by an expression that generates the
desired default value. For example:

    func dump_data(
        Int $offset                  = 0,
        Str :$msg                    = get_std_msg_for($offset),
        Any *@data where {@data > 0} = ('no', $data)
    ) {...}

Note that this solves the type-checking problem for optional parameters
that was described in the previous section, but only if the default
values themselves are type-compatible.

Care must be taken when specifying both optional positional and named
parameters. If C<dump_data()> had been called like so:

    dump_data( msg=>'no results' );

then the positional parameter would attempt to bind to the first
argument (i.e. the label string C<'msg'>), which would cause the entire
call to fail because that value isn't an Int.

Even worse, if the positional parameter hadn't been typed, then the
C<'msg'> label would successfully be assigned to it, so there would be
no labelled argument to bind to the named parameter, and the left-over
C<'no results'> string would be slurped up by C<@data>.

The expression generating the default value must be final component of
the parameter specification, and may be any expression that is valid at
that point in the code. As the previous example illustrates, the
default expression may refer to parameters declared earlier in the
parameter list.

The usual Perl precedence rules apply to the default expression. That's
why, in the previous example, the default values for the slurpy C<@data>
parameter are specified in parentheses. If they had been specified without
the parens:

        Any *@data where {@data > 0} = 'no', $data

then Dios would interpret the C<, $data> as a fourth parameter declaration.

A default specified with a leading C<=> is applied only when no
corresponding argument appears in the argument list, but you can also
specify a default that is applied when there B<is> an argument but it's
C<undef>, by using C<//=> instead of C<=>. For example:

    func dump_data(
        Int $offset                  //= 0,
        Str :$msg                    //= get_std_msg_for($offset),
        Any *@data where {@data > 0}   = ('no', $data)
    ) {...}

With the earlier versions of C<dump_data()>, a call like:

    dump_data(undef);

would have failed...because although we are passing a value for the
positional C<$offset> parameter, that value isn't accepted by the
parameter's type.

But with the C<$offset> parameter's default now specified via a C<//=>,
the default is applied either when the argument is missing, or when it's
provided but is undefined.

Similarly, you can specify a default that is applied when the corresponding
argument is false, using C<||=> instead of C<//=> or C<=>. For example:

    func save_data(@data, :$verified ||= reverify(@data)) {...}

Now, if the labelled argument for C<$verify> is not passed, or if it B<is>
passed, but is false, the C<reverify()> function is automatically called.
Alternatively, you could use the same mechanism to immediately short-circuit
the call if unverified data is passed in:

    func save_data(@data, :$verified ||= return 'failed') {...}


=head4 Defaulting to $_

The parameter default mechanism also allows you to define functions
or methods whose argument defaults to C<$_> (like many of Perl's own
builtins).

For example, you might wish to create an function analogous to C<lc()>
and C<uc()>, but which randomly uppercases and lowercases its argument
(a.k.a. "HoSTagE-cAsE")

    func hc ($str = $_) {
        join  "",
        map   { rand > 0.5 ? uc : lc }
        split //, $str;
    }

    # and later...

    # Pass an explicit string to be hostage-cased
    say hc('Send $1M in small, non-sequential bills!');

    # Hostage-case each successive value in $_
    say hc for @instructions;


=head4 Aliased parameters

All the kinds of parameters discussed so far bind to an argument by
copying it. That's a safe default, but occasionally you want to pass
in variables as arguments, and be able to change them within a
function or method.

So Dios allows parameters to be specified with aliasing semantics
instead of copy semantics...by adding an C<is alias> modifier to their
declaration.

For example:

    func double_chomp ($str is alias = $_) {
        $str =~ s{^\s+}{};
        $str =~ s{\s+$}{};
    }

    func remove_targets (%hash is alias, *@targets) {
        for my $target (@targets) {
            for my $key (keys %hash) {
                delete $hash{$key} if $key ~~ $target;
            }
        }
    }

which would then be called like so:

    # Modify $input
    double_chomp($input);

    # Modify %records
    remove_targets( \%records, qr/mad/, 'bad', \&dangerous );

You can also specify that a named parameter or a slurpy parameter or a
named slurpy parameter should alias its corresponding argument(s).

Note that, under Perl versions earlier than 5.022, aliased parameters
require the Data::Alias module.


=head4 Read-only parameters

You can also specify that a parameter should be readonly within the body
of the subroutine or method, by appending C<is ro> to its definition.

For example:

    func link (:$from is ro, :$to is alias) {...}

In this example, the C<$from> parameter cannot be modified within the
subroutine body, whereas modifications to the C<$to> parameter are
allowed and will propagate back to the argument to which it was bound.

Currently, a parameter cannot be specified as both C<is ro> and
C<is alias>. In the future, C<is ro> may actually imply C<is alias>,
if that proves to be a performance optimization.

Note the differences between:

=over

=item C<is ro>

The parameter is a read-only copy

=item C<is alias>

The parameter is a read-write original

=item I<Neither modifier>

The parameter is a read-write copy

=back

Note that readonly parameters under all versions of Perl
currently require the Const::Fast module.


=head3 Return types

Both functions and methods can be specified with a return type at the
end of their parameter list, preceded by a "long arrow" (C<< --> >>).
That return type can also have a C<where> constraint. For example:

    # Must return an integer...
    func fibonacci(Int $n --> Int) {...}

    # Must return a string that's a valid ID...
    func get_next_ID ( --> Str where {valid_ID($_)} ) {...}

    # Must return a list of Account objects...
    method find_accounts(Code $matcher --> List[Accounts]) {...}

    # Don't return anything (must be called in void context)...
    method exit(-->Void) {...}

Functions and methods with specified return types check that any value
they return is compatible with their specified type, and throw an
exception if the return value isn't.

The special return type C<Void> requires that the function or method
returns only C<undef> or an empty list, I<and> that the function be
called only in void context. An exception is thrown if the return value is
defined; a warning is issued if the call is not in void context.

Any return type apart from C<Void> requires that the function or method
be called in scalar or list context (i.e. that the return value that it
so carefully checked is not just thrown away). If such a function or
method is called in void context, a warning is issued (unless C<no
warnings 'void'> is in effect at the point of the call.

Alternatively, you can allow a function or method with an explicit
return type to also be called in void context by adding <|Void> to its
return-type specifier. For example, this produces a warning:

    func normalize ($text --> Str) {...}

    normalize($data);   # Warning: Useless call to normalize() in void context

whereas this version does not:

    func normalize ($text --> Str|Void) {...}

    normalize($data);   # No warning

To declare a function or method that can return either a scalar
value or a list (e.g. according to call context), use a compound
type. For example:

    method Time::subseconds ( --> List|Str ) {
        wantarray ? ($sec, $usec, $normalized)
                  : sprintf('%d.$06d%s', $sec, $usec, $normalized)
    }

    method Time::HMS ( --> Match[\d\d:\d\d:\d\d]|List[Int] ) {
        wantarray ? ($hour,$min,$sec)
                  : sprintf('%02d:%02d:%02d', $hour, $min, $sec)
    }

=head2 Tail-recursion elimination

Dios provides two keywords that implement pure functional versions of
the built-in "magic C<goto>". They can be used to recursively call the
current subroutine without causing the stack to grow.

The C<callwith> keyword takes a list of arguments and calls the
immediately surrounding subroutine again, passing it the specified
arguments. However, this new call does not add another call-frame to the
stack; instead the new call I<replaces> the current subroutine call on the
stack. So, for example:

    func recursively_process_list($head, *@tail) {
        process($head);

        if (@tail) {
            callwith @tail;   # Same as: @_ = @tail; goto &recursively_process_list;
        }
    }

The C<callsame> keyword takes no arguments, and instead calls the
immediately surrounding subroutine again, passing it the current value
of @_. As with C<callwith>, the call to C<callsame> does not extend
the stack; instead, it once again replaces the current stack-frame.
For example:

    sub recursively_process_list {
        process(shift @_);

        if (@_) {
            callsame;         # Same as: goto &recursively_process_list;
        }
    }

Note that there is currently a syntactic restriction on C<callwith> (but
not on C<callsame>). Specifically, C<callwith> cannot be invoked with a
postfix qualifier. That is, none of these are allowed:

    callwith @args      if @args;
    callwith @args      unless $done;
    callwith get_next() while active();
    callwith get_next() until finished();
    callwith $_         for readline();

When you need to invoke C<callwidth> conditionally, use the block forms
of the various control structures:

    if (@args)         { callwith @args      }
    unless ($done)     { callwith @args      }
    while (active())   { callwith get_next() }
    until (finished()) { callwith get_next() }
    for (readline())   { callwith $_;        }


=head2 Declaring multifuncs and multimethods

Dios supports multiply dispatched functions and methods, which
can be declared using the C<multi> keyword.

Multiple dispatch is where two or more I<variants> of a given
function or method are defined, all of which have the same name,
but each of which has a unique parameter signature. When such
a function or method is called, Dios examines the arguments it
was passed and determines the most appropriate variant to invoke.

The rules for selecting the most appropriate variant as the same
as in Perl 6, namely:

=over

=item 1.

Eliminate every variant number or types of parameters does
not match the number and types of the argument list.

=item 2.

Sort the remaining viable variants according to how constrained their
parameter lists are. If two variants have equally constrained parameter
lists (or parameter lists for which there is no clear ordering of
constrainedness), sort them in order of declaration.

=item 3.

Call the first variant in the sorted list, or throw an exception if
the list is empty.

=back

Multifuncs and multimethods are a useful alternative to internal C<if>/C<elsif>
cascades. For example, instead of:

    func show (Num|Str|Array $x) {
        ref($x) eq 'ARRAY'     ?  '['.join(',', map {dump $_} @$a).']'
      : looks_like_number($x)  ?    $x
      :                           "'$x'"
    }

you could write:

    multi func show (Array $a) { '['.join(',', map {dump $_} @$a).']'}
    multi func show (Num   $n) {   $n   }
    multi func show (Str   $s) { "'$s'" }


Note that, when declaring a multifunc the C<func> keyword may be omitted
(as in Perl 6). So:

    multi func show (Num $n) {...}
    multi func show (Str $s) {...}
    multi func show (Ref $r) {...}

may also be written as just:

    multi show (Num $n) {...}
    multi show (Str $s) {...}
    multi show (Ref $r) {...}

Methods can also be declared C<multi>, in which case the class
of the invocant object is also considered when determining the
most appropriate variant to call. Multimethods are, of course,
inherited, and may be overridden in derived classes.


=head2 Declaring submethods

A I<submethod> is a Perl 6 construct: a method that is
not inherited, and hence may be called only on objects
of the actual class in which it is defined.

Dios provides a C<submethod> keyword to declare such methods.
For example:

    class Account {
        method trace_to (IO $fh) {
            carp "Can't trace a ", ref($self), " object";
        }
    }

    class Account::Traceable is Account {
        submethod trace_to (IO $fh) {
            print {$fh} $self->dump();
        }
    }

Now any objects in a class in the C<Account> hierarchy will complain if
its C<trace_to()> method is called, except objects in class
C<Account::Traceable>, where the submethod will be called instead of the
inherited method.

Most unusually, if the same method is called on an object of any class
that derives from C<Account::Traceable>, the submethod will B<not> be
invoked; the base class's method will be invoked instead.

Submethods are most commonly used to specify initializers and destructors
in Perl 6...and likewise under Dios in Perl 5.


=head3 Declaring an initializer submethod

To specify the equivalent of an Object::Insideout C<:Init> method in Dios,
create a submethod with the special name C<BUILD> and zero or more
named parameters. Like so:

    class Account {

        has $.acct_name;
        has $.balance;

        submethod BUILD (:$name, :$opening_balance) {
            $acct_name = verify($name);
            $balance   = $opening_balance + $::opening_bonus;
        }
    }

When the class constructor is called, and passed a hashref with
labelled arguments, any arguments matching the named parameters
of C<BUILD> are passed to that submethod.

When an object of a derived class is constructed, the C<BUILD> methods
of all its ancestral classes are called in top-down order, and can use
their respective named parameters to extract relevant constructor
arguments for their class.


=head3 Declaring a destructor submethod

You can create the equivalent of on L<Object::InsideOut> C<:Destroy>
method by creating a submethod with the special name C<DESTROY>. Note
that this method is name-mangled internally, so it does not clash with
the C<DESTROY()> method implicitly provided by Object::InsideOut.

A C<DESTROY()> submethod takes no arguments (except C<$self>) and it
is a compile-time error to specify any.

When an object of a derived class is garbage-collected, the C<DESTROY> methods
of all its ancestral classes are called in bottom-up order, and can be used
to free resources or do other cleanup that the garbage collector cannot manage
automatically. For example:

    class Tracked::Agent {
        shared %.agents is ro;

        submethod BUILD (:$ID) {
            $agents{$self} = $ID;
        }

        submethod DESTROY () {
            delete $agents{$self};  # Clean up a resource that the
                                    # garbage collector can't reach.
        }
    }


=head2 Anonymous subroutines and methods

Due to limitations in the behaviour of the Keyword::Simple module
(which Dios uses to implement its various keywords), it is not
currently possible to use the C<func> or C<method> keywords
directly to generate an anonymous function or method:

    my $criterion = func ($n) { 1 <= $n && $n <= 100 };
    # Compilation aborted: 'syntax error, near "= func"'

However, it is possible to work around this limitation,
by placing the anonymous declaration in a C<do> block:

    my $criterion = do{ func ($n) { 1 <= $n && $n <= 100 } };
    # Now compiles and executes as expected


=head1 DIAGNOSTICS

=over

=item C<< Invalid invocant specification: %s in 'use Dios' statement >>

Methods may be given invocants of a name other than C<$self>. However,
the alternative name you specified couldn't be used because it wasn't a
valid identifier.

Respecify the invocant name as a simple identfier (one or more letters,
numbers, and underscores only, but not starting with a number).


=item C<< Can't specify invocant (%s) for %s >>

Explicit invocant parameters can only be declared for methods and submethods.
You attempted to declare it for something else (probably a subroutine).

Did you mean it to be a regular parameter instead? In that case, put a comma
after it, not a colon.


=item C<< Can't declare two parameters named %s in specification of %s >>

Each parameter is a lexical variable in the subroutine, so each must have a
unique name. You attempted to declare two parameters of the same name.

Did you misspell one of them?


=item C<< Can't specify more than one slurpy parameter >>

Slurpy parameters (by definition) suck up all the remaining arguments in
the parameter list. So the second one you declared will never have any
argument bound to it.

Did you want a non-slurpy array or hash instead (i.e. without the C<*>)?


=item C<< Can't specify non-array named slurpy parameter (%s) >>

Slurpy parameters may be named (in which case they collect all the named
arguments of the same name). However, they always collect them as a list,
and so the corresponding parameter must be declared as an array.

Convert the named slurpy hash or scalar you declared to an array, or
else declare the hash or scalar as non-slurpy (by removing the C<*>).


=item C<< Invalid parameter specification: %s in %s declaration >>

You specified something in a parameter list that Dios did not understand.

Review the parameter syntax to see the permitted parameter constructs.


=item C<< 'is ro' requires the Const::Fast module (which could not be loaded) >>

Dios uses the Const::Fast module to ensure "read-only" parameters cannot be modified.
You specified a "read-only" parameter, but Dios couldn't find or load Const::Fast.

Did you need to install Const::Fast? Otherwise, remove the C<is ro> from the parameter
definition.


=item C<< 'is alias' requires the Data::Alias module (which could not be loaded) >>

Under Perl versions prior to 5.22, Dios uses the Data::Alias module to
ensure "alias-only" parameters are aliased to their arguments. You
specified a "aliased" parameter, but Dios couldn't find or load
Data::Alias.

Did you need to install Data::Alias? Or migrate to Perl 5.22?
Otherwise, remove the C<is alias> from the parameter definition
and pass the corresponding argument by reference.


=item C<< submethod DESTROY cannot have a parameter list >>

You declared a destructor submethod with a parameter list,
but destructors aren't called with any arguments.


=item C<< %s takes no arguments >>

The method or subroutine you called was declared to take no arguments,
but you passed some.

If you want to allow extra arguments, either declare them specifically,
or else declare a slurpy array or hash as a catch-all.


=item C<< Unexpected extra argument(s) in call to %s >>

Dios does not allow subroutines or methods to be called with additional
arguments that cannot be bound to one of their parameters. In this case
it encountered extra arguments at the end of the argument list for which
there were no suitable parameter mappings.

Did you need to declare a slurpy parameter at the end of the parameter
list? Otherwise, make sure you only pass as many arguments as the
subroutine or method is defined to take.


=item C<< No argument (%s => %s) found for required named parameter %s >>

You called a subroutine or method which was specified with a named
argument that was marked as being required, but you did not pass a
I<name>C<< => >>I<value> pair for it in the argument list.

Either pass the named argument, or remove the original required status
(by removing the trailing C<!> from the named parameter).


=item C<< No argument found for %s in call to %s >>

You called a subroutine or method which was specified with a positional
parameter that was marked as being required, but you did not pass a
value for it in the argument list.

Either pass the positional argument, or remove the original required
status (by adding a trailing C<?> to the positional parameter).


=item C<< Missing argument for required slurpy parameter %s >>

You called a subroutine or method which was specified with a slurpy
parameter that was marked as being required, but you did not pass a
value for it in the argument list.

Either pass the argument, or remove the original required
status (by removing the trailing C<!> on the slurpy parameter).

=item C<< Argument for %s is not array ref in call to %s >>

You called a subroutine or method that specifies a pass-by-reference
array parameter, but didn't pass it an array reference.

Either pass an array reference, or respecify the array parameter
as a slurpy array.


=item C<< Argument for %s is not hash ref in call to %s >>

You called a subroutine or method that specifies a pass-by-reference
hash parameter, but didn't pass it a hash reference.

Either pass a hash reference, or respecify the hash parameter
as a slurpy hash.



=item C<< Unexpected second value (%s) for named %s parameter in call to %s >>

Named parameters can only be bound once, to a single value. You passed
two or more named arguments with the same name, but only the first could
ever be bound.

Did you misspell the name of the second named argument?
Otherwise, respecify the named parameter as a slurpy named parameter.


=item C<< No suitable %s variant found for call to multi %s >>

The named multifunc or multimethod was called, but none of the variants
found for it matched the types and values of the argument list.


=item C<< Ambiguous call to multi %s. Could invoke any of: %s >>

The named multifunc or multimethod was called, but none of the variants
found for it matched the types and values of the argument list.

You may need to add an extra variant whose parameter list specification
more precisely matches the arguments you passed. Alternatively, you may
need to coerce those arguments to more precisely match the parameter
list of the variant you were attempting to invoke.


=item C<< Call to %s not in void context >>

A function or method with a signature of C<< --> Void >> was called,
but not in void context.

Either call the function or method in void context, or add alternatives
to the return type specification to also allow for non-void calls.


=item C<< Return value %s of call to %s is not of type Void >>

A function or method with a signature of C<< --> Void >> was called,
but returned a defined value that was thrown away.

Either change the return type specification to allow other values to
be returned, or add a C<return;> to ensure the returned value is
suitably "void".


=item C<< Useless call to %s with explicit return type %s in void context >>

A function or method with a signature that requires an actual return
value was called in void context.

To silence this warning, either specify C<no warnings 'void'> before the
call, or else modify the specified return type to include C<Void> as an
alternative.

=back

Dios uses the Dios::Types module for its type-checking,
so it may also generate any of
L<that module's diagnostics|Dios::Type/DIAGNOSTICS>.


=head1 CONFIGURATION AND ENVIRONMENT

Dios requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires Perl 5.14 or later.

Requires the Keyword::Declare, Sub::Uplevel,
Dios::Types, and Data::Dump modules.

If the 'is ro' qualifier is used, also requires the Const::Fast module.

If the 'is alias' qualifier is used under Perl 5.20 or earlier,
also requires the Data::Alias module.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Shared array or hash attributes that are public cannot be accessed
correctly if the chosen accessor style is C<'lvalue'>, because lvalue
subroutines in Perl can only return scalars.

No other bugs have been reported.

Please report any bugs or feature requests to
C<bug-dios@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
