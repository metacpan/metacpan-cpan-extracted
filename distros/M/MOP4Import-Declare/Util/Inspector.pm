#!/usr/bin/env perl
package MOP4Import::Util::Inspector;
use strict;
use warnings;
use Carp;
use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};
BEGIN {
  print STDERR "Using (file '" . __FILE__ . "')\n" if DEBUG and DEBUG >= 2
}

use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
     [lib =>
      doc => "library directory list. SCALAR, ARRAY or ':' separated STRING",
      zsh_completer => ": :_directories",
    ]
   ];

use MOP4Import::NamedCodeAttributes ();

use MOP4Import::Util qw/terse_dump fields_hash fields_symbol
			take_hash_opts_maybe/;
use MOP4Import::Util::FindMethods;

use List::Util ();

sub describe_commands_of {
  (my MY $self, my $classOrObj) = @_;
  my $class = ref $classOrObj || $self->require_module($classOrObj);

  map {$self->format_command_of($class, $_)} $self->list_commands_of($class);
}

sub describe_options_of {
  (my MY $self, my $classOrObj) = @_;
  my $class = ref $classOrObj || $self->require_module($classOrObj);

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
  $self->require_module($pack);
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
  $self->require_module($pack);
  my $symbol = fields_symbol($pack);
  if (my $array = *{$symbol}{ARRAY}) {
    List::Util::uniq(@$array, $self->list_options_onconfigure_of($pack))
  }
  elsif (my $hash = *{$symbol}{HASH}) {
    sort keys %$hash;
  }
  elsif ($pack->can("meta")) {
    $pack->meta->get_attribute_list
  }
  else {
    ();
  }
}

sub list_options_onconfigure_of {
  my ($self, $pack) = @_;
  $self->require_module($pack);
  my $isa = mro::get_linear_isa($pack);
  my %dup;
  map {
    my $symtab = MOP4Import::Util::symtab($_);
    map {
      if (/^onconfigure_(\w+)$/ and not $dup{$1}++) {
        $1
      } else {
        ()
      }
    } sort keys %$symtab;
  } @$isa;
}

sub group_options_of {
  my ($self, $pack, @opt_names) = @_;
  my $fields = fields_hash($pack);
  @opt_names = $self->list_options_of($pack) unless @opt_names;
  my %package;
  my @unknown;
  foreach my $name (@opt_names) {
    next unless $name =~ /^[a-z]/;
    # FieldSpec もどきをここで作る
    my FieldSpec $spec = $fields->{$name};
    if (ref($spec)
        or $spec = $self->get_field_spec_for_onconfigure($pack, $name)) {
      # ok
    }
    else {
      push @unknown, $name;
      next
    }
    push @{$package{$spec->{package}}}, $spec;
  }

  my $isa = mro::get_linear_isa($pack);

  my @grouped = map {
    $package{$_} ? [$_, @{$package{$_}}] : ();
  } @$isa;

  ((@unknown ? ['', @unknown] : ()), @grouped);
}

sub get_field_spec_for_onconfigure {
  (my MY $self, my ($pack, $name)) = @_;
  my $code = $pack->can("onconfigure_$name")
    or return;

  if (my $atts = MOP4Import::NamedCodeAttributes->m4i_CODE_ATTR_dict($code)) {
    $self->create_field_spec_from_code_attribute($pack, $name, $atts);
  }
  else {
    +{package => $pack, name => $name};
  }
}

sub create_field_spec_from_code_attribute {
  (my MY $self, my ($pack, $name, $atts)) = @_;
  my FieldSpec $spec = +{};
  $spec->{package} = $pack;
  $spec->{name} = $name;
  if ($atts->{Doc}) {
    $spec->{doc} = $atts->{Doc};
  }
  if ($atts->{ZshCompleter}) {
    $spec->{zsh_completer} = $atts->{ZshCompleter};
  }
  $spec;
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

  my $atts = $self->info_code_attributes_of($class, $name, $allow_missing)
    or return undef;

  $atts->{Doc};
}

sub info_code_attribute {
  my ($self, $attName, $code) = @_;
  my $atts = MOP4Import::NamedCodeAttributes->m4i_CODE_ATTR_dict($code)
    or return undef;
  $atts->{$attName};
}

sub info_code_attributes_of {
  my ($self, $class, $name, $allow_missing) = @_;
  unless (defined $class and defined $name) {
    Carp::croak "Usage: \$self->info_code_attributes_of(\$class, \$name, ?\$allow_missing\?)"
  }
  $self->require_module($class);
  my $sub = $class->can($name) or do {
    return if $allow_missing;
    Carp::croak "No such method: $name";
  };
  MOP4Import::NamedCodeAttributes->m4i_CODE_ATTR_dict($sub);
}

sub info_methods :method {
  (my MY $self, my ($methodPattern, %opts)) = @_;

  my $groupByClass = delete $opts{group};
  my $detail = delete $opts{detail};
  my $all = delete $opts{all};
  my $inc = delete $opts{inc};
  my $pack = do {
    if (my $name = delete $opts{pack}) {
      $self->require_module($name, MOP4Import::Util::lexpand($inc));
    } else {
      ref $self;
    }
  };

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

  my $isa = mro::get_linear_isa($pack);

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
    sort grep {not $dup{$_}++}@all;
  } else {
    @all;
  }
}

sub require_module {
  (my MY $self, my ($moduleName, @inc)) = @_;

  # In modulino, cmd_help may be called during module loading.
  # At that time, $INC{$moduleFileName} is not yet initialized.
  # This leads to double-require. To avoid this, use symtab check.
  return $moduleName if MOP4Import::Util::maybe_symtab($moduleName);

  @inc = map {split /:/} MOP4Import::Util::lexpand($self->{lib})
    if not @inc and ref $self;
  {
    require Module::Runtime;
    local @INC = (@inc, @INC);
    Module::Runtime::require_module($moduleName);
  }
  my $fn = Module::Runtime::module_notional_filename($moduleName);
  wantarray ? ($moduleName => $INC{$fn}) : $moduleName;
}

sub list_validator_in_module {
  (my MY $self, my ($typeName, $moduleName, @rest)) = @_;
  my $pack = $self->require_module($moduleName, @rest);
  my $sub = $pack->can($typeName);
  my $realType = $sub ? $sub->() : $typeName;
  MOP4Import::Util::list_validator($realType);
}

unless (caller) {
  # To avoid redefinition wornings:
  # cli_run -> cli_help -> cli_inspector -> require MOP4Import::Util::Inspector;
  $INC{"MOP4Import/Util/Inspector.pm"} = __FILE__;

  MY->cli_run(\@ARGV);
}

1;
