package GraphQL::Houtou::Role::FieldsEither;

use 5.014;
use strict;
use warnings;

use Role::Tiny;
with qw(GraphQL::Houtou::Role::FieldDeprecation);

# Marker role for schema objects that own field maps.

1;
