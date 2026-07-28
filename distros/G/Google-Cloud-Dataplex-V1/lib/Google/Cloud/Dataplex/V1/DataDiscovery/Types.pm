package Google::Cloud::Dataplex::V1::DataDiscovery::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataDiscoverySpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec'];

coerce 'DataDiscoverySpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec'->new($_) };

declare 'RepeatedDataDiscoverySpec',
    as ArrayRef[DataDiscoverySpec()];

coerce 'RepeatedDataDiscoverySpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec'->new($_) } @$_ ] };

declare 'MapStringDataDiscoverySpec',
    as HashRef[DataDiscoverySpec()];

declare 'BigQueryPublishingConfig',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::BigQueryPublishingConfig'];

coerce 'BigQueryPublishingConfig',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::BigQueryPublishingConfig'->new($_) };

declare 'RepeatedBigQueryPublishingConfig',
    as ArrayRef[BigQueryPublishingConfig()];

coerce 'RepeatedBigQueryPublishingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::BigQueryPublishingConfig'->new($_) } @$_ ] };

declare 'MapStringBigQueryPublishingConfig',
    as HashRef[BigQueryPublishingConfig()];

declare 'TableType',
    as (Int | Str);

declare 'StorageConfig',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig'];

coerce 'StorageConfig',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig'->new($_) };

declare 'RepeatedStorageConfig',
    as ArrayRef[StorageConfig()];

coerce 'RepeatedStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig'->new($_) } @$_ ] };

declare 'MapStringStorageConfig',
    as HashRef[StorageConfig()];

declare 'CsvOptions',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig::CsvOptions'];

coerce 'CsvOptions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig::CsvOptions'->new($_) };

declare 'RepeatedCsvOptions',
    as ArrayRef[CsvOptions()];

coerce 'RepeatedCsvOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig::CsvOptions'->new($_) } @$_ ] };

declare 'MapStringCsvOptions',
    as HashRef[CsvOptions()];

declare 'JsonOptions',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig::JsonOptions'];

coerce 'JsonOptions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig::JsonOptions'->new($_) };

declare 'RepeatedJsonOptions',
    as ArrayRef[JsonOptions()];

coerce 'RepeatedJsonOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig::JsonOptions'->new($_) } @$_ ] };

declare 'MapStringJsonOptions',
    as HashRef[JsonOptions()];

declare 'UnstructuredDataOptions',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig::UnstructuredDataOptions'];

coerce 'UnstructuredDataOptions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig::UnstructuredDataOptions'->new($_) };

declare 'RepeatedUnstructuredDataOptions',
    as ArrayRef[UnstructuredDataOptions()];

coerce 'RepeatedUnstructuredDataOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoverySpec::StorageConfig::UnstructuredDataOptions'->new($_) } @$_ ] };

declare 'MapStringUnstructuredDataOptions',
    as HashRef[UnstructuredDataOptions()];

declare 'DataDiscoveryResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoveryResult'];

coerce 'DataDiscoveryResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoveryResult'->new($_) };

declare 'RepeatedDataDiscoveryResult',
    as ArrayRef[DataDiscoveryResult()];

coerce 'RepeatedDataDiscoveryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoveryResult'->new($_) } @$_ ] };

declare 'MapStringDataDiscoveryResult',
    as HashRef[DataDiscoveryResult()];

declare 'BigQueryPublishing',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoveryResult::BigQueryPublishing'];

coerce 'BigQueryPublishing',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoveryResult::BigQueryPublishing'->new($_) };

declare 'RepeatedBigQueryPublishing',
    as ArrayRef[BigQueryPublishing()];

coerce 'RepeatedBigQueryPublishing',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoveryResult::BigQueryPublishing'->new($_) } @$_ ] };

declare 'MapStringBigQueryPublishing',
    as HashRef[BigQueryPublishing()];

declare 'ScanStatistics',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoveryResult::ScanStatistics'];

coerce 'ScanStatistics',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoveryResult::ScanStatistics'->new($_) };

declare 'RepeatedScanStatistics',
    as ArrayRef[ScanStatistics()];

coerce 'RepeatedScanStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDiscovery::DataDiscoveryResult::ScanStatistics'->new($_) } @$_ ] };

declare 'MapStringScanStatistics',
    as HashRef[ScanStatistics()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::DataDiscovery::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
