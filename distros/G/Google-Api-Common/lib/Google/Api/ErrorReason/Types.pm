package Google::Api::ErrorReason::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ErrorReason',
    as (Int | Str);

1;
