package JMAP::Validation::Checks::Number;

use JMAP::Validation;
use JMAP::Validation::Tests::Number;
use Test2::Bundle::Extended;

use JSON::Typist;

our $is_number = validator(sub {
  my (%params) = @_;

  return (ref($params{got}) || '') eq 'JSON::Typist::Number';
});

our $is_number_or_null = validator(sub {
  my (%params) = @_;

 if (defined $params{got}) {
   return unless JMAP::Validation::validate(
     $params{got},
     $is_number,
   );
 }

 return 1;
});

1;
