package Google::Cloud::BigQuery::V2::ManagedTableType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ManagedTableType',
    as (Int | Str);

1;
