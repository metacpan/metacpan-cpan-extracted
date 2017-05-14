package JMAP::Validation::Tests::Number;

use strict;
use warnings;

sub is_number {
  my ($value) = @_;

  return (ref($value) || '') eq 'JSON::Typist::Number';
}

1;
