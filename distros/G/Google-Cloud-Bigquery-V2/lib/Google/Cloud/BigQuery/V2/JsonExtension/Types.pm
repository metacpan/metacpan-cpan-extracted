package Google::Cloud::BigQuery::V2::JsonExtension::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JsonExtension',
    as (Int | Str);

1;
