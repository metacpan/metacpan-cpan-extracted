package Google::Cloud::BigQuery::V2::FileSetSpecificationType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FileSetSpecType',
    as (Int | Str);

1;
