package Google::Cloud::Bigquery::V2::BiglakeMetastoreDatasetReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BigLakeMetastoreDatasetReference',
    as InstanceOf['Google::Cloud::Bigquery::V2::BiglakeMetastoreDatasetReference::BigLakeMetastoreDatasetReference'];

coerce 'BigLakeMetastoreDatasetReference',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::BiglakeMetastoreDatasetReference::BigLakeMetastoreDatasetReference'->new($_) };

declare 'RepeatedBigLakeMetastoreDatasetReference',
    as ArrayRef[BigLakeMetastoreDatasetReference()];

coerce 'RepeatedBigLakeMetastoreDatasetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::BiglakeMetastoreDatasetReference::BigLakeMetastoreDatasetReference'->new($_) } @$_ ] };

declare 'MapStringBigLakeMetastoreDatasetReference',
    as HashRef[BigLakeMetastoreDatasetReference()];

1;
