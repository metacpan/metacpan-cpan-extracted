package Google::Api::FieldBehavior::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FieldBehavior',
    as (Int | Str);

1;
