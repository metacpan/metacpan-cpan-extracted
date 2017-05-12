
package LaTeX::PGF::Diagram2D::NumberPrinter;

use 5.000000;
use strict;
use warnings;

use Carp;

our @ISA = qw();

our $VERSION = '1.00';

sub new
{
  my $self = undef;
  if($#_ < 0) {
    croak "Usage: LaTeX::PGF::Diagram2D::NumberPrinter->new()";
  } else {
    my $class = shift;
    $self = {
      'd' => undef,		# Data
      'ds' => ',',		# Decimal sign
    };
    bless($self, $class);
  }
  return $self;
}



sub set_decimal_sign
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$numberprinter->set_decimal_sign(character)";
  } else {
    $self = shift;
    $self->{'ds'} = shift;
  }
  return $self;
}



sub init
{
  my $self = undef;
  if($#_ < 0) {
    croak "Usage: \$numberprinter->init()";
  } else {
    $self = shift;
    $self->{'d'} = {};
  }
  return $self;
}


sub add_number_string
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$numberprinter->add_number(value)";
  } else {
    $self = shift;
    my $v = shift;
    my $t = $v;
    my $mantisse = undef;
    my $exponent = 0;
    if("$t" =~ /(.*)[Ee](.*)/o) {
      $mantisse = $1; $exponent = $2; $exponent = 0 + $exponent;
    } else {
      $mantisse = $t;
    }
    while($exponent % 3) {
      $mantisse = 10.0 * $mantisse; $exponent--;
    }
    while(abs($mantisse) >= 1000.0) {
      $mantisse = $mantisse / 1000.0; $exponent += 3;
    }
    $mantisse = sprintf("%g", $mantisse);
    my $ci = index($mantisse, ".");
    if($ci >= 0) {
      my $add = length($mantisse) - $ci - 1;
      if($add > 0) {
        my $d = $self->{'d'};
        if(exists($d->{"$exponent"})) {
	  if($add > $d->{"$exponent"}) {
	    $d->{"$exponent"} = $add;
	  }
	} else {
	  $d->{"$exponent"} = $add;
	}
      }
    }
  }
  return $self;
}



sub add_number
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$numberprinter->add_number(value)";
  } else {
    $self = shift;
    my $v = shift;
    $self->add_number_string( sprintf("%g", $v) );
  }
  return $self;
}



# File handler
# Value to print



sub write_number_string
{
  my $self = undef;
  if($#_ < 2) {
    croak "Usage: \$numberprinter->write_number_string(filehandle, number)";
  } else {
    $self = shift;
    my $fh = shift;	# File handler
    my $v = shift;	# Value to print
    my $mantisse = undef;
    my $exponent = 0;
    if("$v" =~ /(.*)[Ee](.*)/o) {
      $mantisse = $1; $exponent = $2; $exponent = 0 + $exponent;
    } else {
      $mantisse = $v;
    }
    while($exponent % 3) {
      $mantisse = 10.0 * $mantisse; $exponent--;
    }
    while(abs($mantisse) >= 1000.0) {
      $mantisse = $mantisse / 1000.0; $exponent += 3;
    }
    my $p1 = undef; my $p2 = undef;
    if("$mantisse" =~ /(.*)\.(.*)/o) {
      $p1 = $1; $p2 = $2;
    } else {
      $p1 = $mantisse;
    }
    print $fh "\\(";
    print $fh "$p1";
    if(defined($p2)) {
      print $fh "" . $self->{'ds'} . $p2;
    }
    my $d = $self->{'d'};
    if(exists($d->{"$exponent"})) {
      my $add = $d->{"$exponent"};
      if(defined($p2)) {
        my $l = length($p2);
	while($l++ < $add) { print $fh "0"; }
      } else {
        print $fh $self->{'ds'};
	while($add--) { print $fh "0"; }
      }
    }
    if($exponent != 0) {
      print $fh "\\cdot{}{10}^{" . $exponent . "}";
    }
    print $fh "\\)";
  }
  return $self;
}



sub write_number
{
  my $self = undef;
  if($#_ < 2) {
    croak "Usage: \$numberprinter->write_number(filehandle, number)";
  } else {
    $self = shift;
    my $fh = shift;	# File handler
    my $v = shift;	# Value to print
    $self->write_number_string( $fh, sprintf("%g", $v) );
  }
  return $self;
}



1;
__END__

=head1 NAME

LaTeX::PGF::Diagram2D::NumberPrinter - Perl extension for drawing 2D diagrams

=head1 DESCRIPTION

This class is used internally by the LaTeX::PGF::Diagram2D package.

=cut

