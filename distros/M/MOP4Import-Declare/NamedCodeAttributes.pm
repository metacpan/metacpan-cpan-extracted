package MOP4Import::NamedCodeAttributes;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro qw/c3/;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

use attributes ();

use MOP4Import::Declare -as_base;

my %named_code_attributes;

sub MODIFY_CODE_ATTRIBUTES {
  my $caller = [caller(1)];
  shift->cli_CODE_ATTR_dispatch($caller, @_);
}

sub cli_CODE_ATTR_dispatch {
  my ($pack, $caller, $code, @attrs) = @_;
  (undef, my ($filename, $lineno)) = @$caller;
  print "\n\n### Got CODE_ATTR at file $filename line $lineno: "
    . MOP4Import::Util::terse_dump(@attrs)."\n\n"
    if DEBUG;
  my @unknowns;
  foreach my $attStr (@attrs) {
    my ($attName, $text) = $attStr =~ m{^([A-Z]\w*)(?:\((.*)\))?\z}s or do {
      push @unknowns, $attStr;
    };

    # If the attribute is value-less (like :method), use 1 as it's value.
    my $value = defined $text ? _strip_quotes($text) : 1;

    if (my $sub = $pack->can(my $method = "cli_CODE_ATTR_declare__$attName")) {
      print STDERR "# calling $method for $pack\n" if DEBUG;
      $sub->($pack, $code, $value, $attName, $filename, $lineno);
    } elsif ($sub = $pack->can($method = "cli_CODE_ATTR_build__$attName")) {
      print STDERR "# calling $method for $pack\n" if DEBUG;
      $pack->cli_CODE_ATTR_add(
        $attName, $code,
        scalar($sub->($pack, $code, $value, $attName)),
        $filename, $lineno
      );
    } else {
      print STDERR "# No CODE_ATTR handler for $attName in $pack: $attStr\n"
        if DEBUG;
      push @unknowns, $attStr;
    };
  }
  @unknowns;
}

sub cli_CODE_ATTR_add {
  my ($pack, $attName, $code, $value, $filename, $lineno) = @_;
  $named_code_attributes{$attName}{$code} = [$value, $filename, $lineno];
}

sub cli_CODE_ATTR_get {
  my ($pack, $attName, $code) = @_;
  unless (defined $code and ref $code eq 'CODE') {
    Carp::croak "Invalid type argument: ".MOP4Import::Util::terse_dump($code);
  }
  my $entry = $named_code_attributes{$attName}{$code}
    or return;
  wantarray ? @$entry : $entry->[0];
}

sub _strip_quotes {
  return undef if not defined $_[0];
  $_[0] =~ s/^\"(.*?)\"\z/$1/s;
  $_[0] =~ s/^\'(.*?)\'\z/$1/s;
  $_[0];
}

#========================================
# :Doc() attribute.
#

sub cli_CODE_ATTR_build__Doc {
  my ($pack, $code, $value, $attName) = @_;
  $value;
}


1;
