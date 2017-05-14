package JMAP::Validation::Tests::Boolean;

use strict;
use warnings;

sub is_boolean{
  my ($value) = @_;

  return (ref($value) || '') eq 'JSON::PP::Boolean';
}

1;
