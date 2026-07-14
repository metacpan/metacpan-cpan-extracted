package Google::Cloud::BigQuery::V2::DecimalTargetTypes::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DecimalTargetType',
    as (Int | Str);

1;
