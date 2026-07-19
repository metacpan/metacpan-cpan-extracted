package GraphQL::Houtou::Role::FieldsOutput;

use 5.014;
use strict;
use warnings;

use Role::Tiny;
with qw(
  GraphQL::Houtou::Role::FieldDeprecation
  GraphQL::Houtou::Role::FieldsEither
);

# Marker role for output schema objects that expose field maps.

1;
