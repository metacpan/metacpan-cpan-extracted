package Lib::SymbolRef;
# $Id: SymbolRef.pm,v 1.4 2004/03/21 02:17:02 kiesling Exp $

# Copyright © 2001-2004 Robert Kiesling, rkies@cpan.org.
#
# Licensed under the same terms as Perl.  Refer to the file,
# "Artistic," for information.

$VERSION=0.53;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
push @ISA, qw( Exporter DB );
@EXPORT_OK=qw($VERSION);

require Exporter;
require Carp;
use Lib::ModuleSymbol;

sub TIESCALAR {
  my ($package, $name, $refer) = @_;
  my $obj = { name => $name, refs=>() };
  bless $obj, $package;
  return $obj;
}

sub TIEHANDLE {
  my ($package, $name, $refer) = @_;
  ### Until re-tied.
  no warnings;
  my $obj = { name => $name, refs => () };
  use warnings;
  bless $obj, $package;
  return $obj;
}

sub TIEARRAY {
}

sub PRINTF {
  my $self = shift;
  my $fmt = shift;
}

sub FETCH {
  return undef;
}

sub GETC {
  return undef;
}

sub READ {
  return undef;
}

sub OPEN {
  return undef;
}

sub READLINE {
  return undef;
}

sub STORE {
  return undef;
}


# ---- Hash methods -----


sub TIEHASH {
  my ($varref, $package, $callingpkg ) = @_;
  my $obj = [ name => $varref, callingpkg => $callingpkg, {%$hr} ];
  bless $obj, $package;
  print "TIEHASH: $varref, $package, $callingpkg\n";
  return $obj;
}

sub FIRSTKEY {
}

sub CLEAR {
}

# ---- Instance methods

sub name {
  my $self = shift;
  if (@_) {
    $self -> {name} = shift;
  }
  return $self -> {name}
}

1;

