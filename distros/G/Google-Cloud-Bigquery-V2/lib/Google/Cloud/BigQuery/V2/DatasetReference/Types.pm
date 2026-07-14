package Google::Cloud::BigQuery::V2::DatasetReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatasetReference',
    as InstanceOf['Google::Cloud::BigQuery::V2::DatasetReference::DatasetReference'];

coerce 'DatasetReference',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::DatasetReference::DatasetReference'->new($_) };

declare 'RepeatedDatasetReference',
    as ArrayRef[DatasetReference()];

coerce 'RepeatedDatasetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::DatasetReference::DatasetReference'->new($_) } @$_ ] };

declare 'MapStringDatasetReference',
    as HashRef[DatasetReference()];

1;
