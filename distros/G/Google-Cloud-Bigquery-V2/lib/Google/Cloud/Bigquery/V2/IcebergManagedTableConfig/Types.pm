package Google::Cloud::Bigquery::V2::IcebergManagedTableConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IcebergManagedTableConfiguration',
    as InstanceOf['Google::Cloud::Bigquery::V2::IcebergManagedTableConfig::IcebergManagedTableConfiguration'];

coerce 'IcebergManagedTableConfiguration',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::IcebergManagedTableConfig::IcebergManagedTableConfiguration'->new($_) };

declare 'RepeatedIcebergManagedTableConfiguration',
    as ArrayRef[IcebergManagedTableConfiguration()];

coerce 'RepeatedIcebergManagedTableConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::IcebergManagedTableConfig::IcebergManagedTableConfiguration'->new($_) } @$_ ] };

declare 'MapStringIcebergManagedTableConfiguration',
    as HashRef[IcebergManagedTableConfiguration()];

declare 'DataFileFormat',
    as (Int | Str);

1;
