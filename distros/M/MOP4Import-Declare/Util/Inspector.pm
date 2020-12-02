package MOP4Import::Util::Inspector;
use strict;
use warnings;
use MOP4Import::Base::Configure -as_base;

use MOP4Import::NamedCodeAttributes ();

use MOP4Import::Util qw/terse_dump fields_hash fields_symbol
			take_hash_opts_maybe/;
use MOP4Import::Util::FindMethods;

use List::Util ();

sub describe_commands_of {
  (my MY $self, my $classOrObj) = @_;
  my $class = ref $classOrObj || $classOrObj;

  map {$self->format_command_of($class, $_)} $self->list_commands_of($class);
}

sub describe_options_of {
  (my MY $self, my $classOrObj) = @_;
  my $class = ref $classOrObj || $classOrObj;

  my @msg;

  my @options = $self->group_options_of($class);
  my $maxlen = $self->max_option_length($class);

  foreach my $group (@options) {
    my ($pkg, @fields) = @$group;
    push @msg, <<END;

Options from $pkg:
END
    foreach my FieldSpec $fs (@fields) {
      push @msg, $self->format_option($fs, $maxlen);
    }
  }
  @msg;
}

sub list_commands_of {
  my ($self, $pack) = @_;
  FindMethods($pack, sub {s/^cmd_//});
}

sub format_command_of {
  my ($self, $class, $name) = @_;
  "  ".join("        "
            , $name
            , $self->info_command_doc_of($class, $name) // '')."\n";
}

sub list_options_of {
  my ($self, $pack) = @_;
  my $symbol = fields_symbol($pack);
  if (my $array = *{$symbol}{ARRAY}) {
    @$array
  } elsif (my $hash = *{$symbol}{HASH}) {
    sort keys %$hash;
  } else {
    ();
  }
}

sub group_options_of {
  my ($self, $pack, @opt_names) = @_;
  my $fields = fields_hash($pack);
  @opt_names = $self->list_options_of($pack) unless @opt_names;
  my %package;
  my @unknown;
  foreach my $name (@opt_names) {
    next unless $name =~ /^[a-z]/;
    ref(my FieldSpec $spec = $fields->{$name}) or do {
      push @unknown, $name;
      next
    };
    push @{$package{$spec->{package}}}, $spec;
  }

  my $isa = mro::get_linear_isa($pack);

  my @grouped = map {
    $package{$_} ? [$_, @{$package{$_}}] : ();
  } @$isa;

  ((@unknown ? ['', @unknown] : ()), @grouped);
}

sub max_option_length {
  my ($self, $pack) = @_;
  my $fields = fields_hash($pack);
  my @name = grep {/^[a-z]/} $self->list_options_of($pack);
  List::Util::max(map {length} @name);
}

sub format_option {
  (my MY $self, my FieldSpec $fs, my $maxlen) = @_;
  my $len = ($maxlen // 16);
  sprintf "  --%-${len}s  %s\n", $fs->{name}, $fs->{doc} // "";
}

sub is_getter_of {
  my ($self, $pack, $subName) = @_;
  my $fields = fields_hash($pack);
  exists $fields->{$subName} && $pack->can($subName);
}

sub info_command_doc_of {
  my ($self, $class, $name) = @_;
  $self->info_method_doc_of($class, "cmd_$name");
}

sub info_method_doc_of {
  my ($self, $class, $name, $allow_missing) = @_;
  my $sub = $class->can($name) or do {
    return if $allow_missing;
    Carp::croak "No such method: $name";
  };
  $self->info_code_attribute(Doc => $sub);
}

sub info_code_attribute {
  my ($self, $name, $code) = @_;
  my ($atts) = grep {
    ref $_ eq 'HASH'
  } attributes::get($code)
  or return undef;
  $atts->{$name}
}

sub info_methods :method {
  (my MY $self, my ($methodPattern, %opts)) = @_;

  my $groupByClass = delete $opts{group};
  my $detail = delete $opts{detail};
  my $all = delete $opts{all};

  unless (keys %opts == 0) {
    Carp::croak "Unknown options: ".join(", ", sort keys %opts);
  }

  my $re = do {
    if (not defined $methodPattern or $methodPattern eq '') {
      qr{^[a-z]\w+\z}
    }
    elsif (ref $methodPattern eq 'Regexp') {
      $methodPattern
    }
    elsif ($methodPattern =~ m{^/(.*)/\z}) {
      qr{$1}
    } elsif ($methodPattern =~ /\*/) {
      require Text::Glob;
      Text::Glob::glob_to_regex($methodPattern);
    } else {
      qr{^$methodPattern};
    }
  };

  my $isa = mro::get_linear_isa(ref $self);

  my @all = map {
    my $symtab = MOP4Import::Util::symtab($_);
    my @names = grep {not /\W/ and $_ =~ $re} keys %$symtab;
    my @found = grep {
      my $entry = $symtab->{$_};
      if (ref \$entry eq 'GLOB' and my $code = *{$entry}{CODE}) {
        $all || MOP4Import::Util::has_method_attr($code);
      }
    } @names;
    if (not @found) {
      ()
    } elsif ($detail) {
      +{class => $_, methods => [map {
        my $doc = $self->info_method_doc($_);
        [$_, $doc ? $doc : ()];
      } sort @found]}
    } elsif ($groupByClass) {
      [$_, sort @found]
    } else {
      @found;
    }
  } @$isa;

  if (not $detail and not $groupByClass) {
    my %dup;
    sort grep {not $dup{$_}++}@all
  } else {
    @all;
  }
}

1;

