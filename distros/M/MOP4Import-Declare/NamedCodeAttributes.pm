package MOP4Import::NamedCodeAttributes;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro qw/c3/;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

use attributes ();

use Exporter qw/import/;
our @EXPORT = qw(
                  MODIFY_CODE_ATTRIBUTES
                  FETCH_CODE_ATTRIBUTES
                  m4i_CODE_ATTR_get
              );

use MOP4Import::Util ();

use MOP4Import::Opts;

my %named_code_attributes;

sub MODIFY_CODE_ATTRIBUTES {
  my $caller = [caller(1)];
  (undef, my ($filename, $lineno)) = @$caller;
  print "\n\n### Got CODE_ATTR at file $filename line $lineno: "
    . MOP4Import::Util::terse_dump(@_[2..$#_])."\n\n"
    if DEBUG;

  # Call m4i_CODE_ATTR_dict to make sure builtin atts are registered.
  m4i_CODE_ATTR_dict($_[0], $_[1]);

  my $pack = shift;
  m4i_CODE_ATTR_dispatch($pack, $caller, @_);
}

sub FETCH_CODE_ATTRIBUTES {
  my ($pack, $code) = @_;
  my $atts = m4i_CODE_ATTR_dict($pack, $code)
    or return;
  map {
    if (defined (my $val = $atts->{$_})) {
      # XXX: escape this!
      "$_($val)"
    } else {
      $_;
    }
  } keys %$atts;
}

sub _fetch_builtin_attrs {
  # Sorry for using the internal function, but I need this.
  attributes::_fetch_attrs($_[0]);
}

sub m4i_CODE_ATTR_dispatch {
  my ($pack, $caller, $code, @attrs) = @_;
  (undef, my ($filename, $lineno)) = @$caller;
  my @unknowns;
  foreach my $attStr (@attrs) {
    my ($attName, $text) = $attStr =~ m{^([A-Z]\w*)(?:\((.*)\))?\z}s or do {
      push @unknowns, $attStr;
    };

    # If the attribute is value-less (like :method), use 1 as it's value.
    my $value = defined $text ? _strip_quotes($text) : 1;

    if (my $sub = $pack->can(my $method = "m4i_CODE_ATTR_declare__$attName")) {
      print STDERR "# calling $method for $pack\n" if DEBUG;
      $sub->($pack, $code, $value, $attName, $filename, $lineno);
    } elsif ($sub = $pack->can($method = "m4i_CODE_ATTR_build__$attName")) {
      print STDERR "# calling $method for $pack\n" if DEBUG;
      m4i_CODE_ATTR_add(
        $pack,
        $attName, $code,
        scalar($sub->($pack, $code, $value, $attName)),
      );
    } else {
      print STDERR "# No CODE_ATTR handler for $attName in $pack: $attStr\n"
        if DEBUG;
      push @unknowns, $attStr;
    };
  }
  @unknowns;
}

sub m4i_CODE_ATTR_add {
  my ($_pack, $attName, $code, $value) = @_;
  $named_code_attributes{$code}{$attName} = $value;
}

sub m4i_CODE_ATTR_dict {
  my ($_pack, $code) = @_;

  $named_code_attributes{$code} //= do {
    my $atts = +{};

    # To make sure infinite recursion of FETCH_CODE_ATTRIBUTES,
    # I want to avoid calling attributes::get($code) here.
    foreach my $attDesc (_fetch_builtin_attrs($code)) {
      my ($name, $value) = $attDesc =~ m{^([^\(]+)([\(].*)?\z}
        or Carp::croak "Can't parse attribute $attDesc";
      $value =~ s/^\(|\)\z//g if defined $value;
      $atts->{$name} = $value // 1;
    }

    $atts;
  };
}

sub m4i_CODE_ATTR_get {
  my ($_pack, $attName, $code) = @_;
  unless (defined $code and ref $code eq 'CODE') {
    Carp::croak "Invalid type argument: ".MOP4Import::Util::terse_dump($code);
  }
  $named_code_attributes{$code}{$attName};
}

sub _strip_quotes {
  return undef if not defined $_[0];
  $_[0] =~ s/^\"(.*?)\"\z/$1/s;
  $_[0] =~ s/^\'(.*?)\'\z/$1/s;
  $_[0];
}

#========================================

sub declare_code_attributes {
  (my $myPack, my Opts $opts, my (@decls)) = m4i_args(@_);

  foreach my $desc (@decls) {
    # [$name => @opts] でも良いとする。@opts の使い方は後で決める。
    my ($name, @opts) = MOP4Import::Util::lexpand($desc);
    my $sym = MOP4Import::Util::globref($opts->{destpkg}, "m4i_CODE_ATTR_build__$name");
    *$sym = sub {
      my ($pack, $code, $value, $attName) = @_;
      $value;
    };
  }
}

__PACKAGE__->declare_code_attributes(__PACKAGE__, (
  'MetaOnly',
  'Doc',
  'ZshCompleter',
));

our @EXPORT_OK = MOP4Import::Util::function_names(from => __PACKAGE__);

1;
