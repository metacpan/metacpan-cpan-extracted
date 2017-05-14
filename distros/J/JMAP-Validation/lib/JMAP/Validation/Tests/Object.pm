package JMAP::Validation::Tests::Object;

use strict;
use warnings;

use Test2::Bundle::Extended;

sub is_object {
  my ($value) = @_;

  return ref($value) eq 'HASH';
}

1;
