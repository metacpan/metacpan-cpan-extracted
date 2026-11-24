package Google::Cloud::Chronicle::V1::BigQueryExport::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BigQueryExportPackage',
    as (Int | Str);

declare 'LatestExportJobState',
    as (Int | Str);

declare 'BigQueryExport',
    as InstanceOf['Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport'];

coerce 'BigQueryExport',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport'->new($_) };

declare 'RepeatedBigQueryExport',
    as ArrayRef[BigQueryExport()];

coerce 'RepeatedBigQueryExport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport'->new($_) } @$_ ] };

declare 'MapStringBigQueryExport',
    as HashRef[BigQueryExport()];

declare 'DataSourceExportSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::BigQueryExport::DataSourceExportSettings'];

coerce 'DataSourceExportSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::BigQueryExport::DataSourceExportSettings'->new($_) };

declare 'RepeatedDataSourceExportSettings',
    as ArrayRef[DataSourceExportSettings()];

coerce 'RepeatedDataSourceExportSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::BigQueryExport::DataSourceExportSettings'->new($_) } @$_ ] };

declare 'MapStringDataSourceExportSettings',
    as HashRef[DataSourceExportSettings()];

declare 'GetBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::BigQueryExport::GetBigQueryExportRequest'];

coerce 'GetBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::BigQueryExport::GetBigQueryExportRequest'->new($_) };

declare 'RepeatedGetBigQueryExportRequest',
    as ArrayRef[GetBigQueryExportRequest()];

coerce 'RepeatedGetBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::BigQueryExport::GetBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringGetBigQueryExportRequest',
    as HashRef[GetBigQueryExportRequest()];

declare 'UpdateBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::BigQueryExport::UpdateBigQueryExportRequest'];

coerce 'UpdateBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::BigQueryExport::UpdateBigQueryExportRequest'->new($_) };

declare 'RepeatedUpdateBigQueryExportRequest',
    as ArrayRef[UpdateBigQueryExportRequest()];

coerce 'RepeatedUpdateBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::BigQueryExport::UpdateBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBigQueryExportRequest',
    as HashRef[UpdateBigQueryExportRequest()];

declare 'ProvisionBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::BigQueryExport::ProvisionBigQueryExportRequest'];

coerce 'ProvisionBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::BigQueryExport::ProvisionBigQueryExportRequest'->new($_) };

declare 'RepeatedProvisionBigQueryExportRequest',
    as ArrayRef[ProvisionBigQueryExportRequest()];

coerce 'RepeatedProvisionBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::BigQueryExport::ProvisionBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringProvisionBigQueryExportRequest',
    as HashRef[ProvisionBigQueryExportRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::BigQueryExport::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
