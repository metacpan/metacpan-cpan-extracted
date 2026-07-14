package Google::Cloud::BigQuery::V2::BiglakeConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BigLakeConfiguration',
    as InstanceOf['Google::Cloud::BigQuery::V2::BiglakeConfig::BigLakeConfiguration'];

coerce 'BigLakeConfiguration',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::BiglakeConfig::BigLakeConfiguration'->new($_) };

declare 'RepeatedBigLakeConfiguration',
    as ArrayRef[BigLakeConfiguration()];

coerce 'RepeatedBigLakeConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::BiglakeConfig::BigLakeConfiguration'->new($_) } @$_ ] };

declare 'MapStringBigLakeConfiguration',
    as HashRef[BigLakeConfiguration()];

declare 'FileFormat',
    as (Int | Str);

declare 'TableFormat',
    as (Int | Str);

1;
