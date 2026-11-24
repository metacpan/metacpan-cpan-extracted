package Google::Cloud::Retail::V2beta::ExportConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OutputConfig',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig'];

coerce 'OutputConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig'->new($_) };

declare 'RepeatedOutputConfig',
    as ArrayRef[OutputConfig()];

coerce 'RepeatedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig'->new($_) } @$_ ] };

declare 'MapStringOutputConfig',
    as HashRef[OutputConfig()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'BigQueryDestination',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig::BigQueryDestination'];

coerce 'BigQueryDestination',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig::BigQueryDestination'->new($_) };

declare 'RepeatedBigQueryDestination',
    as ArrayRef[BigQueryDestination()];

coerce 'RepeatedBigQueryDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig::BigQueryDestination'->new($_) } @$_ ] };

declare 'MapStringBigQueryDestination',
    as HashRef[BigQueryDestination()];

declare 'ExportErrorsConfig',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::ExportErrorsConfig'];

coerce 'ExportErrorsConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportErrorsConfig'->new($_) };

declare 'RepeatedExportErrorsConfig',
    as ArrayRef[ExportErrorsConfig()];

coerce 'RepeatedExportErrorsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportErrorsConfig'->new($_) } @$_ ] };

declare 'MapStringExportErrorsConfig',
    as HashRef[ExportErrorsConfig()];

declare 'ExportProductsRequest',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::ExportProductsRequest'];

coerce 'ExportProductsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportProductsRequest'->new($_) };

declare 'RepeatedExportProductsRequest',
    as ArrayRef[ExportProductsRequest()];

coerce 'RepeatedExportProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportProductsRequest'->new($_) } @$_ ] };

declare 'MapStringExportProductsRequest',
    as HashRef[ExportProductsRequest()];

declare 'ExportUserEventsRequest',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsRequest'];

coerce 'ExportUserEventsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsRequest'->new($_) };

declare 'RepeatedExportUserEventsRequest',
    as ArrayRef[ExportUserEventsRequest()];

coerce 'RepeatedExportUserEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsRequest'->new($_) } @$_ ] };

declare 'MapStringExportUserEventsRequest',
    as HashRef[ExportUserEventsRequest()];

declare 'ExportAnalyticsMetricsRequest',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsRequest'];

coerce 'ExportAnalyticsMetricsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsRequest'->new($_) };

declare 'RepeatedExportAnalyticsMetricsRequest',
    as ArrayRef[ExportAnalyticsMetricsRequest()];

coerce 'RepeatedExportAnalyticsMetricsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsRequest'->new($_) } @$_ ] };

declare 'MapStringExportAnalyticsMetricsRequest',
    as HashRef[ExportAnalyticsMetricsRequest()];

declare 'ExportMetadata',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::ExportMetadata'];

coerce 'ExportMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportMetadata'->new($_) };

declare 'RepeatedExportMetadata',
    as ArrayRef[ExportMetadata()];

coerce 'RepeatedExportMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportMetadata'->new($_) } @$_ ] };

declare 'MapStringExportMetadata',
    as HashRef[ExportMetadata()];

declare 'ExportProductsResponse',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::ExportProductsResponse'];

coerce 'ExportProductsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportProductsResponse'->new($_) };

declare 'RepeatedExportProductsResponse',
    as ArrayRef[ExportProductsResponse()];

coerce 'RepeatedExportProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportProductsResponse'->new($_) } @$_ ] };

declare 'MapStringExportProductsResponse',
    as HashRef[ExportProductsResponse()];

declare 'ExportUserEventsResponse',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsResponse'];

coerce 'ExportUserEventsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsResponse'->new($_) };

declare 'RepeatedExportUserEventsResponse',
    as ArrayRef[ExportUserEventsResponse()];

coerce 'RepeatedExportUserEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsResponse'->new($_) } @$_ ] };

declare 'MapStringExportUserEventsResponse',
    as HashRef[ExportUserEventsResponse()];

declare 'ExportAnalyticsMetricsResponse',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsResponse'];

coerce 'ExportAnalyticsMetricsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsResponse'->new($_) };

declare 'RepeatedExportAnalyticsMetricsResponse',
    as ArrayRef[ExportAnalyticsMetricsResponse()];

coerce 'RepeatedExportAnalyticsMetricsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsResponse'->new($_) } @$_ ] };

declare 'MapStringExportAnalyticsMetricsResponse',
    as HashRef[ExportAnalyticsMetricsResponse()];

declare 'OutputResult',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::OutputResult'];

coerce 'OutputResult',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::OutputResult'->new($_) };

declare 'RepeatedOutputResult',
    as ArrayRef[OutputResult()];

coerce 'RepeatedOutputResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::OutputResult'->new($_) } @$_ ] };

declare 'MapStringOutputResult',
    as HashRef[OutputResult()];

declare 'BigQueryOutputResult',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::BigQueryOutputResult'];

coerce 'BigQueryOutputResult',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::BigQueryOutputResult'->new($_) };

declare 'RepeatedBigQueryOutputResult',
    as ArrayRef[BigQueryOutputResult()];

coerce 'RepeatedBigQueryOutputResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::BigQueryOutputResult'->new($_) } @$_ ] };

declare 'MapStringBigQueryOutputResult',
    as HashRef[BigQueryOutputResult()];

declare 'GcsOutputResult',
    as InstanceOf['Google::Cloud::Retail::V2beta::ExportConfig::GcsOutputResult'];

coerce 'GcsOutputResult',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ExportConfig::GcsOutputResult'->new($_) };

declare 'RepeatedGcsOutputResult',
    as ArrayRef[GcsOutputResult()];

coerce 'RepeatedGcsOutputResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ExportConfig::GcsOutputResult'->new($_) } @$_ ] };

declare 'MapStringGcsOutputResult',
    as HashRef[GcsOutputResult()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2beta::ExportConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
