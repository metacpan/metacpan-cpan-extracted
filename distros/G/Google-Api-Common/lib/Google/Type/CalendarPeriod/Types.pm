package Google::Type::CalendarPeriod::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CalendarPeriod',
    as (Int | Str);

1;
