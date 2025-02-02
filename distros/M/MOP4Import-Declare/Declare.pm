# -*- coding: utf-8 -*-
package MOP4Import::Declare;
use 5.010;
use strict;
use warnings qw(FATAL all NONFATAL misc);
our $VERSION = '0.061';
use Carp;
use mro qw/c3/;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

use Sub::Util ();

print STDERR "\nUsing ".__PACKAGE__. " = $VERSION (file '"
  . __FILE__ . "')\n"
  if DEBUG;

use MOP4Import::Opts
  qw/
      Opts
      m4i_args
      m4i_opts
    /;
use MOP4Import::Util;
use MOP4Import::FieldSpec;
use MOP4Import::NamedCodeAttributes
  qw(MODIFY_CODE_ATTRIBUTES
     FETCH_CODE_ATTRIBUTES
     /^m4i_CODE_ATTR_/
     declare_code_attributes
  );

#========================================

our %FIELDS;

sub import :MetaOnly {
  my ($myPack, @decls) = @_;

  m4i_log_start() if DEBUG;

  my Opts $opts = m4i_opts([caller]);

  @decls = $myPack->default_exports($opts) unless @decls;

  $myPack->dispatch_declare($opts, $myPack->always_exports($opts), @decls);

  my $tasks;
  if ($tasks = $opts->{delayed_tasks} and @$tasks) {
    print STDERR " Calling delayed tasks for $opts->{destpkg}\n" if DEBUG;
    $_->($opts) for @$tasks;
  }

  m4i_log_end($opts->{callpack}) if DEBUG;
}

sub m4i_file_line_of :method :MetaOnly {
  (my $myPack, my Opts $opts) = @_;
  " at $opts->{filename} line $opts->{line}";
}

sub m4i_stash :method :MetaOnly {
  (my $myPack, my Opts $opts) = @_;
  $opts->{stash}{$myPack} //= +{};
}

#
# `default_exports` is a hook to list exported symbols
# when the module is used without arguments, like "use Foo".
# Default implementation get them from `@EXPORT`.
#
sub default_exports {
  (my $myPack, my Opts $opts) = @_;
  my $symtab = MOP4Import::Util::symtab($myPack);
  my $sym = $symtab->{EXPORT};
  if ($sym and my $export = *{$sym}{ARRAY}) {
    print STDERR "HAS \@EXPORT: $myPack" if DEBUG;
    @$export
  } else {
    print STDERR "NO \@EXPORT: $myPack"  if DEBUG;
    ();
  }
}

sub declare_default_exports {
  (my $myPack, my Opts $opts, my (@decls)) = m4i_args(@_);

  my $export = MOP4Import::Util::ensure_symbol_has_array(
    globref($opts->{objpkg}, 'EXPORT')
  );

  push @$export, @decls;
}

sub always_exports {
  (my $myPack, my Opts $opts) = @_;
  qw(-strict);
}

sub dispatch_declare :MetaOnly {
  (my $myPack, my Opts $opts, my (@decls)) = m4i_args(@_);

  print STDERR "$myPack->dispatch_declare("
    .terse_dump($opts, @decls).")\n" if DEBUG;

  foreach my $declSpec (@decls) {

    croak "Undefined pragma!" unless defined $declSpec;

    if (not ref $declSpec
        or ref $declSpec eq 'Regexp') {

      $myPack->dispatch_import($opts, $declSpec);

    } elsif (ref $declSpec eq 'ARRAY') {

      $myPack->dispatch_declare_pragma($opts, @$declSpec);

    } elsif (ref $declSpec eq 'CODE') {

      $declSpec->($myPack, $opts);

    } else {
      croak "Invalid pragma: ".terse_dump($declSpec);
    }
  }
}

our %SIGIL_MAP = qw(* GLOB
		    $ SCALAR
		    % HASH
		    @ ARRAY
		    & CODE);

sub dispatch_import :MetaOnly {
  (my $myPack, my Opts $opts, my ($declSpec)) = m4i_args(@_);

  my ($name, $exported);

  if (not ref $declSpec and $declSpec =~ /^-([A-Za-z]\w*)$/) {

    return $myPack->dispatch_declare_pragma($opts, $1);

  } else {

    $myPack->dispatch_import_no_pragma($opts, $declSpec);
  }
}

sub dispatch_import_no_pragma :MetaOnly {
  (my $myPack, my Opts $opts, my (@declSpec)) = m4i_args(@_);
  foreach my $declSpec (@declSpec) {

    if (ref $declSpec eq 'Regexp') {
      $myPack->import_by_regexp($opts, $declSpec);
    }
    elsif ($declSpec =~ /^([\*\$\%\@\&])?([A-Za-z]\w*)$/) {
      if ($1) {
        my $kind = $SIGIL_MAP{$1};
        $myPack->can("import_$kind")
          ->($myPack, $opts, $1, $kind, $2);
      } else {
        $myPack->import_NAME($opts => $2);
      }
    } else {
      croak "Invalid import spec: $declSpec";
    }
  }
}

sub import_by_regexp :MetaOnly {
  (my $myPack, my Opts $opts, my ($pattern)) = m4i_args(@_);

  my $symtab = MOP4Import::Util::symtab($myPack);
  foreach my $name (keys %$symtab) {
    next unless $name =~ $pattern;
    *{globref($opts->{destpkg}, $name)} = $symtab->{$name};
  }
}

sub import_NAME :MetaOnly {
  (my $myPack, my Opts $opts, my ($name)) = m4i_args(@_);

  my $exported = safe_globref($myPack, $name);

  print STDERR " Declaring $name in $opts->{destpkg} as "
    .terse_dump($exported)."\n" if DEBUG;

  *{globref($opts->{destpkg}, $name)} = $exported;
}

sub import_GLOB :MetaOnly {
  (my $myPack, my Opts $opts, my ($sigil, $kind, $name)) = m4i_args(@_);

  my $exported = safe_globref($myPack, $name);

  print STDERR " Declaring $name in $opts->{destpkg} as "
    .terse_dump($exported)."\n" if DEBUG;

  *{globref($opts->{destpkg}, $name)} = $exported;
}

sub import_SIGIL :MetaOnly {
  (my $myPack, my Opts $opts, my ($sigil, $kind, $name)) = m4i_args(@_);

  my $exported = *{safe_globref($myPack, $name)}{$kind};

  print STDERR " Declaring $sigil$opts->{destpkg}::$name"
    . ", import from $sigil${myPack}::$name"
    . " (=".terse_dump($exported).")\n" if DEBUG;

  *{globref($opts->{destpkg}, $name)} = $exported;
}

*import_SCALAR = *import_SIGIL; *import_SCALAR = *import_SIGIL;
*import_ARRAY = *import_SIGIL; *import_ARRAY = *import_SIGIL;
*import_HASH = *import_SIGIL; *import_HASH = *import_SIGIL;
*import_CODE = *import_SIGIL; *import_CODE = *import_SIGIL;

sub dispatch_declare_pragma :MetaOnly {
  (my $myPack, my Opts $opts, my ($pragma, @args)) = m4i_args(@_);
  if ($pragma =~ /^[A-Za-z]/
      and my $sub = $myPack->can("declare_$pragma")) {
    $sub->($myPack, $opts, @args);
  } else {
    croak "No such pragma: \`use $myPack\ [".terse_dump($pragma)."]`"
      . $myPack->m4i_file_line_of($opts);
  }
}

#========================================

# You may want to override these pragrams.
sub declare_default_pragma :MetaOnly {
  (my $myPack, my Opts $opts) = m4i_args(@_);
  $myPack->declare_c3($opts);
}

sub declare_strict :MetaOnly {
  (my $myPack, my Opts $opts) = m4i_args(@_);
  $_->import for qw(strict warnings); # I prefer fatalized warnings, but...
}

# Not enabled by default.
sub declare_fatal :MetaOnly {
  (my $myPack, my Opts $opts) = m4i_args(@_);
  warnings->import(qw(FATAL all NONFATAL misc));
}

sub declare_c3 :MetaOnly {
  (my $myPack, my Opts $opts) = m4i_args(@_);
  mro::set_mro($opts->{destpkg}, 'c3');
}

#========================================

#
# Just for readability
#
#   use XXX [import => qw/X Y Z/];
#
sub declare_import :MetaOnly {
  (my $myPack, my Opts $opts, my (@import)) = m4i_args(@_);

  $myPack->dispatch_import_no_pragma($opts, @import);
}

#========================================

sub declare_fileless_base :MetaOnly {
  (my $myPack, my Opts $opts, my (@base)) = m4i_args(@_);

  $myPack->declare___add_isa($opts->{objpkg}, @base);

  $myPack->declare_fields($opts);
}

*declare_base = *declare_parent; *declare_base = *declare_parent;

sub declare_parent :MetaOnly {
  (my $myPack, my Opts $opts, my (@base)) = m4i_args(@_);

  foreach my $fn (@base) {
    (my $cp = $fn) =~ s{::|\'}{/}g;
    require "$cp.pm";
  }

  $myPack->declare_fileless_base($opts, @base);
}

sub declare_as_base :MetaOnly {
  (my $myPack, my Opts $opts, my (@fields)) = m4i_args(@_);

  print STDERR "Class $opts->{objpkg} inherits $myPack\n"
    if DEBUG;

  $myPack->declare_default_pragma($opts); # strict, mro c3...

  $myPack->declare___add_isa($opts->{objpkg}, $myPack);

  $myPack->declare_fields($opts, @fields);

  $myPack->declare_private_constant($opts, MY => $opts->{objpkg}, or_ignore => 1);
}

sub declare___add_isa :MetaOnly {
  my ($myPack, $objpkg, @parents) = @_;

  print STDERR "Class $objpkg extends ".terse_dump(@parents)."\n"
    if DEBUG;

  my $isa = MOP4Import::Util::isa_array($objpkg);

  my $using_c3 = mro::get_mro($objpkg) eq 'c3';

  if (DEBUG) {
    print STDERR " $objpkg (MRO=",mro::get_mro($objpkg),") ISA "
      , terse_dump(mro::get_linear_isa($objpkg)), "\n";
    print STDERR " Adding $_ (MRO=",mro::get_mro($_),") ISA "
      , terse_dump(mro::get_linear_isa($_))
      , "\n" for @parents;
  }

  my @new = grep {
    my $parent = $_;
    $parent ne $objpkg
      and not grep {$parent eq $_} @$isa;
  } @parents;

  if ($using_c3) {
    local $@;
    foreach my $parent (@new) {
      my $cur = mro::get_linear_isa($objpkg);
      my $adding = mro::get_linear_isa($parent);
      eval {
	unshift @$isa, $parent;
	# if ($] < 5.014) {
	#   mro::method_changed_in($objpkg);
	#   mro::get_linear_isa($objpkg);
	# }
      };
      if ($@) {
        croak "Can't add base '$parent' to '$objpkg' (\n"
          .  "  $objpkg ISA ".terse_dump($cur).")\n"
          .  "  Adding $parent ISA ".terse_dump($adding)
          ."\n) because of this error: " . $@;
      }
    }
  } else {
    push @$isa, @new;
  }
}

# I'm afraid this 'as' pragma could invite ambiguous interpretation.
# But in following case, I can't find any other pragma name.
#
#   use XXX [as => 'YYY']
#
# So, let's define `declare_as` as an alias of `declare_naming`.
#
*declare_as = *declare_naming; *declare_as = *declare_naming;

sub declare_naming :MetaOnly {
  (my $myPack, my Opts $opts, my ($name)) = m4i_args(@_);

  unless (defined $name and $name ne '') {
    croak "Usage: use ${myPack} [naming => NAME]";
  }

  $myPack->declare_constant($opts, $name => $myPack);
}

sub declare_inc :MetaOnly {
  (my $myPack, my Opts $opts, my ($pkg)) = m4i_args(@_);
  $pkg //= $opts->{objpkg};
  $pkg =~ s{::}{/}g;
  $INC{$pkg . '.pm'} = 1;
}

sub declare_constant :MetaOnly {
  (my $myPack, my Opts $opts, my ($name, $value, %opts)) = m4i_args(@_);

  $myPack->declare_private_constant($opts, $name, $value, %opts);

  my $export = MOP4Import::Util::ensure_symbol_has_array(
    globref($opts->{objpkg}, 'EXPORT')
  );
  push @$export, $name;
  print STDERR " constant $name is added to default exports of "
    . $opts->{objpkg}. "\n" if DEBUG;
}

sub declare_private_constant :MetaOnly {
  (my $myPack, my Opts $opts, my ($name, $value, %opts)) = m4i_args(@_);

  my $or_ignore = delete $opts{or_ignore};
  if (keys %opts) {
    Carp::croak("Unknown options: ". join ", ", sort keys(%opts));
  }

  my $my_sym = globref($opts->{objpkg}, $name);
  if (*{$my_sym}{CODE}) {
    return if $or_ignore;
    croak "constant $opts->{objpkg}::$name is already defined";
  }

  MOP4Import::Util::define_constant($my_sym, $value);
}

sub declare_fields :MetaOnly {
  (my $myPack, my Opts $opts, my (@fields)) = m4i_args(@_);

  my $extended = fields_hash($opts->{objpkg});
  my $fields_array = fields_array($opts->{objpkg});

  my $isFirst = not $myPack->JSON_TYPE_HANDLER->lookup_json_type($opts->{objpkg});

  # Import all fields from super class
  foreach my $super_class (@{*{globref($opts->{objpkg}, 'ISA')}{ARRAY}}) {
    my $super = fields_hash($super_class);
    next unless $super;


    my $super_names = fields_array($super_class);
    my @names = @$super_names ? @$super_names : keys %$super;
    foreach my $name (@names) {
      next if defined $extended->{$name};
      print STDERR "  Field $opts->{objpkg}.$name is inherited "
	. "from $super_class.\n" if DEBUG;
      my $anyFieldSpec = $extended->{$name} = do {
        my $origin = $super->{$name};
         # XXX: mark origin in this clone?
        ref $origin ? $origin->clone : $origin;
      };
      push @$fields_array, $name;
    }

    $myPack->JSON_TYPE_HANDLER->inherit_json_type($opts->{objpkg}, $super_class) if $isFirst;

  }

  {
    my %dup;
    foreach my $spec (@fields) {
      my ($name) = ref $spec ? @$spec : $spec;
      if ($dup{$name}++) {
        croak "Duplicate field decl! $name";
      }
    }
  }


  my $field_class = do {
    # XXX: objpkg? destpkg?
    if (my $sub = $opts->{destpkg}->can("FieldSpec")) {
      $sub->();
    } else {
      $myPack->FieldSpec;
    }
  };

  print STDERR "  FieldSpec is: $field_class\n" if DEBUG;

  $myPack->JSON_TYPE_HANDLER->declare_json_type_record($opts->{objpkg});

  $myPack->declare___field($opts, $field_class, ref $_ ? @$_ : $_) for @fields;

  $opts->{objpkg}; # XXX:
}

sub declare___field :MetaOnly {
  (my $myPack, my Opts $opts, my ($field_class, $name, @rest)) = m4i_args(@_);
  print STDERR "  Declaring field $opts->{objpkg}.$name " if DEBUG;
  my $extended = fields_hash($opts->{objpkg});
  my $fields_array = fields_array($opts->{objpkg});

  my $spec = fields_hash($field_class);
  my (@early, @delayed);
  while (my ($k, $v) = splice @rest, 0, 2) {
    unless (defined $k) {
      croak "Undefined field spec key for $opts->{objpkg}.$name in $opts->{callpack}";
    }
    if ($k =~ /^[A-Za-z]/) {
      if (my $sub = $myPack->can("declare___field_with_$k")) {
	push @delayed, [$sub, $k, $v];
	next;
      } elsif (exists $spec->{$k}) {
	push @early, $k, $v;
	next;
      }
    }
    croak "Unknown option for $opts->{objpkg}.$name in $opts->{callpack}: "
      . ".$k";
  }

  my FieldSpec $fs = $extended->{$name}
    = $field_class->new(@early, name => $name);
  $fs->{package} = $opts->{objpkg};
  print STDERR " with $myPack $field_class => ", terse_dump($fs), "\n"
    if DEBUG;
  push @$fields_array, $name;

  # Create accessor for all public fields.
  if ($name =~ /^[a-z]/i and not $fs->{no_getter}) {
    if (my $sym = MOP4Import::Util::symtab($opts->{objpkg})->{$name}) {
      if (*{$sym}{CODE}) {
        croak "Accessor $opts->{objpkg}::$name is redefined!\nIf you really want to define the accessor by hand, please specify fields spec like: [$name => no_getter => 1, ...].";
      }
    }

    *{globref($opts->{objpkg}, $name)}
      = Sub::Util::set_subname(join("::", $opts->{objpkg}, $name)
                               , sub :method { $_[0]->{$name} });
  }

  foreach my $delayed (@delayed) {
    my ($sub, $k, $v) = @$delayed;
    $sub->($myPack, $opts, $fs, $k, $v);
  }

  if ($fs->{name} !~ /^_/) {
    $myPack->JSON_TYPE_HANDLER->register_json_type_of_field(
      $opts, $opts->{objpkg}, $fs->{name},
      $fs->{json_type} || $opts->{default_json_type} || 'string'
    );
  }

  $fs;
}

sub declare___field_with_default :MetaOnly {
  (my $myPack, my Opts $opts, my FieldSpec $fs, my ($k, $v)) = m4i_args(@_);

  $fs->{$k} = $v;

  if (ref $v eq 'CODE') {
    *{globref($opts->{objpkg}, "default_$fs->{name}")} = $v;
  } else {
    $myPack->declare_private_constant($opts, "default_$fs->{name}", $v);
  }
}

sub JSON_TYPE_HANDLER {
  require MOP4Import::Util::JSON_TYPE;
  'MOP4Import::Util::JSON_TYPE';
}

sub declare_alias :MetaOnly {
  (my $myPack, my Opts $opts, my ($name, $alias)) = m4i_args(@_);
  print STDERR " Declaring alias $name in $opts->{destpkg} as $alias\n" if DEBUG;
  my $sym = globref($opts->{destpkg}, $name);
  if (*{$sym}{CODE}) {
    croak "Subroutine (alias) $opts->{destpkg}::$name redefined";
  }
  *$sym = sub () {$alias};
}

# Set(override) default value for inherited fields
#
# [defaults =>
#    fieldName => defaultValue, ...
# ]
#
sub declare_defaults :MetaOnly {
  (my $myPack, my Opts $opts, my (@kvlist)) = m4i_args(@_);

  my $fields = fields_hash($opts->{objpkg});

  while (my ($k, $v) = splice @kvlist, 0, 2) {
    my FieldSpec $fs = $fields->{$k}
      or Carp::croak "No such field: $k";
    $fs->{default} = $v;
    my $fn = "default_$k";
    $myPack->declare_private_constant($opts, $fn, $v);
  }
}
*declare_override_defaults = *declare_defaults;
*declare_override_defaults = *declare_defaults;

sub declare_map_methods :MetaOnly {
  (my $myPack, my Opts $opts, my (@pairs)) = m4i_args(@_);

  foreach my $pair (@pairs) {
    my ($from, $to) = @$pair;
    my $sub = $opts->{objpkg}->can($to)
      or croak "Can't find method $to in (parent of) $opts->{objpkg}";
    *{globref($opts->{objpkg}, $from)} = $sub;
  }
}

sub declare_carp_not :MetaOnly {
  (my $myPack, my Opts $opts, my (@carp_not)) = m4i_args(@_);

  unless (@carp_not) {
    push @carp_not, $myPack;
  }

  my $name = 'CARP_NOT';

  print STDERR "Declaring \@$opts->{objpkg}.$name = ".terse_dump(@carp_not)
    if DEBUG;

  *{globref($opts->{objpkg}, $name)} = \@carp_not;
}

{
  #
  # Below does equiv of `our @CARP_NOT = qw/ MOP4Import::Util /;`
  #
  __PACKAGE__->declare_carp_not(MOP4Import::Opts::m4i_fake_opts(__PACKAGE__),
                                qw/
                                   MOP4Import::Util
                                   /
                                 );
}

1;


