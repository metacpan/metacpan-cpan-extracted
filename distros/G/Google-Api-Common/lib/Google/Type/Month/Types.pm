package Google::Type::Month::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Month',
    as (Int | Str);

1;
