package Google::Cloud::BigQuery::V2::PartitioningDefinition::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PartitioningDefinition',
    as InstanceOf['Google::Cloud::BigQuery::V2::PartitioningDefinition::PartitioningDefinition'];

coerce 'PartitioningDefinition',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::PartitioningDefinition::PartitioningDefinition'->new($_) };

declare 'RepeatedPartitioningDefinition',
    as ArrayRef[PartitioningDefinition()];

coerce 'RepeatedPartitioningDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::PartitioningDefinition::PartitioningDefinition'->new($_) } @$_ ] };

declare 'MapStringPartitioningDefinition',
    as HashRef[PartitioningDefinition()];

declare 'PartitionedColumn',
    as InstanceOf['Google::Cloud::BigQuery::V2::PartitioningDefinition::PartitionedColumn'];

coerce 'PartitionedColumn',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::PartitioningDefinition::PartitionedColumn'->new($_) };

declare 'RepeatedPartitionedColumn',
    as ArrayRef[PartitionedColumn()];

coerce 'RepeatedPartitionedColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::PartitioningDefinition::PartitionedColumn'->new($_) } @$_ ] };

declare 'MapStringPartitionedColumn',
    as HashRef[PartitionedColumn()];

1;
