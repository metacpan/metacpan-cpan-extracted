use strict;
use warnings;

package MAS::TIFF::Rational;

sub new {
  my $class = shift;
  my ($numerator, $denominator) = @_;
  
  return bless [$numerator, $denominator], $class;
}

sub numerator { return shift->[0] }
sub denominator { return shift->[1] }

sub to_string {
  my $self = shift;

  if ($self->denominator == 1) {
    return $self->numerator;
  }
  else {
    return sprintf("(%d / %d)", $self->numerator, $self->denominator);
  }
}

1;
