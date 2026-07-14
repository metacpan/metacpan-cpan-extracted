package Google::Cloud::Bigquery::V2::HivePartitioning::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HivePartitioningOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::HivePartitioning::HivePartitioningOptions'];

coerce 'HivePartitioningOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::HivePartitioning::HivePartitioningOptions'->new($_) };

declare 'RepeatedHivePartitioningOptions',
    as ArrayRef[HivePartitioningOptions()];

coerce 'RepeatedHivePartitioningOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::HivePartitioning::HivePartitioningOptions'->new($_) } @$_ ] };

declare 'MapStringHivePartitioningOptions',
    as HashRef[HivePartitioningOptions()];

1;
