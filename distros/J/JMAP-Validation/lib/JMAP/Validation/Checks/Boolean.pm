package JMAP::Validation::Checks::Boolean;

use Test2::Bundle::Extended;

our $is_boolean = validator(sub {
  my (%params) = @_;

  return (ref($params{got}) || '') eq 'JSON::PP::Boolean';
});

1;
