package Google::Cloud::Bigquery::V2::SystemProcedure::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SystemProcedure',
    as (Int | Str);

1;
