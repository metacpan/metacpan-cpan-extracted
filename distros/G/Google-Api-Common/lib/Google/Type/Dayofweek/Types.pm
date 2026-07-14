package Google::Type::Dayofweek::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DayOfWeek',
    as (Int | Str);

1;
