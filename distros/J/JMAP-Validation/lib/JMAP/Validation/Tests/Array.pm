package JMAP::Validation::Tests::Array;

use strict;
use warnings;

sub is_array {
  my ($value) = @_;

  return ref($value) eq 'ARRAY';
}

1;
