package Google::Cloud::Capacityplanner::V1beta::UsageService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'QueryUsageHistoriesRequest',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::QueryUsageHistoriesRequest'];

coerce 'QueryUsageHistoriesRequest',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryUsageHistoriesRequest'->new($_) };

declare 'RepeatedQueryUsageHistoriesRequest',
    as ArrayRef[QueryUsageHistoriesRequest()];

coerce 'RepeatedQueryUsageHistoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryUsageHistoriesRequest'->new($_) } @$_ ] };

declare 'MapStringQueryUsageHistoriesRequest',
    as HashRef[QueryUsageHistoriesRequest()];

declare 'QueryUsageHistoriesResponse',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::QueryUsageHistoriesResponse'];

coerce 'QueryUsageHistoriesResponse',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryUsageHistoriesResponse'->new($_) };

declare 'RepeatedQueryUsageHistoriesResponse',
    as ArrayRef[QueryUsageHistoriesResponse()];

coerce 'RepeatedQueryUsageHistoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryUsageHistoriesResponse'->new($_) } @$_ ] };

declare 'MapStringQueryUsageHistoriesResponse',
    as HashRef[QueryUsageHistoriesResponse()];

declare 'QueryForecastsRequest',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::QueryForecastsRequest'];

coerce 'QueryForecastsRequest',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryForecastsRequest'->new($_) };

declare 'RepeatedQueryForecastsRequest',
    as ArrayRef[QueryForecastsRequest()];

coerce 'RepeatedQueryForecastsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryForecastsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryForecastsRequest',
    as HashRef[QueryForecastsRequest()];

declare 'QueryForecastsResponse',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::QueryForecastsResponse'];

coerce 'QueryForecastsResponse',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryForecastsResponse'->new($_) };

declare 'RepeatedQueryForecastsResponse',
    as ArrayRef[QueryForecastsResponse()];

coerce 'RepeatedQueryForecastsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryForecastsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryForecastsResponse',
    as HashRef[QueryForecastsResponse()];

declare 'QueryReservationsRequest',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::QueryReservationsRequest'];

coerce 'QueryReservationsRequest',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryReservationsRequest'->new($_) };

declare 'RepeatedQueryReservationsRequest',
    as ArrayRef[QueryReservationsRequest()];

coerce 'RepeatedQueryReservationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryReservationsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryReservationsRequest',
    as HashRef[QueryReservationsRequest()];

declare 'ReservationType',
    as (Int | Str);

declare 'ShareType',
    as (Int | Str);

declare 'OwnershipType',
    as (Int | Str);

declare 'ReservationDataLevel',
    as (Int | Str);

declare 'QueryReservationsResponse',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::QueryReservationsResponse'];

coerce 'QueryReservationsResponse',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryReservationsResponse'->new($_) };

declare 'RepeatedQueryReservationsResponse',
    as ArrayRef[QueryReservationsResponse()];

coerce 'RepeatedQueryReservationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryReservationsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryReservationsResponse',
    as HashRef[QueryReservationsResponse()];

declare 'Point',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::Point'];

coerce 'Point',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::Point'->new($_) };

declare 'RepeatedPoint',
    as ArrayRef[Point()];

coerce 'RepeatedPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::Point'->new($_) } @$_ ] };

declare 'MapStringPoint',
    as HashRef[Point()];

declare 'Forecast',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::Forecast'];

coerce 'Forecast',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::Forecast'->new($_) };

declare 'RepeatedForecast',
    as ArrayRef[Forecast()];

coerce 'RepeatedForecast',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::Forecast'->new($_) } @$_ ] };

declare 'MapStringForecast',
    as HashRef[Forecast()];

declare 'ForecastType',
    as (Int | Str);

declare 'Bounds',
    as (Int | Str);

declare 'PredictionInterval',
    as (Int | Str);

declare 'UsageHistory',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::UsageHistory'];

coerce 'UsageHistory',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::UsageHistory'->new($_) };

declare 'RepeatedUsageHistory',
    as ArrayRef[UsageHistory()];

coerce 'RepeatedUsageHistory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::UsageHistory'->new($_) } @$_ ] };

declare 'MapStringUsageHistory',
    as HashRef[UsageHistory()];

declare 'AggregationMethod',
    as (Int | Str);

declare 'TimeSeries',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::TimeSeries'];

coerce 'TimeSeries',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::TimeSeries'->new($_) };

declare 'RepeatedTimeSeries',
    as ArrayRef[TimeSeries()];

coerce 'RepeatedTimeSeries',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::TimeSeries'->new($_) } @$_ ] };

declare 'MapStringTimeSeries',
    as HashRef[TimeSeries()];

declare 'LocationType',
    as (Int | Str);

declare 'ReservationData',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::ReservationData'];

coerce 'ReservationData',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ReservationData'->new($_) };

declare 'RepeatedReservationData',
    as ArrayRef[ReservationData()];

coerce 'RepeatedReservationData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ReservationData'->new($_) } @$_ ] };

declare 'MapStringReservationData',
    as HashRef[ReservationData()];

declare 'MachineShape',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::MachineShape'];

coerce 'MachineShape',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::MachineShape'->new($_) };

declare 'RepeatedMachineShape',
    as ArrayRef[MachineShape()];

coerce 'RepeatedMachineShape',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::MachineShape'->new($_) } @$_ ] };

declare 'MapStringMachineShape',
    as HashRef[MachineShape()];

declare 'ExportUsageHistoriesRequest',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::ExportUsageHistoriesRequest'];

coerce 'ExportUsageHistoriesRequest',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportUsageHistoriesRequest'->new($_) };

declare 'RepeatedExportUsageHistoriesRequest',
    as ArrayRef[ExportUsageHistoriesRequest()];

coerce 'RepeatedExportUsageHistoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportUsageHistoriesRequest'->new($_) } @$_ ] };

declare 'MapStringExportUsageHistoriesRequest',
    as HashRef[ExportUsageHistoriesRequest()];

declare 'ExportForecastsRequest',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::ExportForecastsRequest'];

coerce 'ExportForecastsRequest',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportForecastsRequest'->new($_) };

declare 'RepeatedExportForecastsRequest',
    as ArrayRef[ExportForecastsRequest()];

coerce 'RepeatedExportForecastsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportForecastsRequest'->new($_) } @$_ ] };

declare 'MapStringExportForecastsRequest',
    as HashRef[ExportForecastsRequest()];

declare 'ExportReservationsUsageRequest',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::ExportReservationsUsageRequest'];

coerce 'ExportReservationsUsageRequest',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportReservationsUsageRequest'->new($_) };

declare 'RepeatedExportReservationsUsageRequest',
    as ArrayRef[ExportReservationsUsageRequest()];

coerce 'RepeatedExportReservationsUsageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportReservationsUsageRequest'->new($_) } @$_ ] };

declare 'MapStringExportReservationsUsageRequest',
    as HashRef[ExportReservationsUsageRequest()];

declare 'ShareType',
    as (Int | Str);

declare 'OutputConfig',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::OutputConfig'];

coerce 'OutputConfig',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::OutputConfig'->new($_) };

declare 'RepeatedOutputConfig',
    as ArrayRef[OutputConfig()];

coerce 'RepeatedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::OutputConfig'->new($_) } @$_ ] };

declare 'MapStringOutputConfig',
    as HashRef[OutputConfig()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'BigQueryDestination',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::BigQueryDestination'];

coerce 'BigQueryDestination',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::BigQueryDestination'->new($_) };

declare 'RepeatedBigQueryDestination',
    as ArrayRef[BigQueryDestination()];

coerce 'RepeatedBigQueryDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::BigQueryDestination'->new($_) } @$_ ] };

declare 'MapStringBigQueryDestination',
    as HashRef[BigQueryDestination()];

declare 'PartitionKey',
    as (Int | Str);

declare 'WriteDisposition',
    as (Int | Str);

declare 'CreateDisposition',
    as (Int | Str);

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ExportUsageHistoriesResponse',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::ExportUsageHistoriesResponse'];

coerce 'ExportUsageHistoriesResponse',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportUsageHistoriesResponse'->new($_) };

declare 'RepeatedExportUsageHistoriesResponse',
    as ArrayRef[ExportUsageHistoriesResponse()];

coerce 'RepeatedExportUsageHistoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportUsageHistoriesResponse'->new($_) } @$_ ] };

declare 'MapStringExportUsageHistoriesResponse',
    as HashRef[ExportUsageHistoriesResponse()];

declare 'ExportForecastsResponse',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::ExportForecastsResponse'];

coerce 'ExportForecastsResponse',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportForecastsResponse'->new($_) };

declare 'RepeatedExportForecastsResponse',
    as ArrayRef[ExportForecastsResponse()];

coerce 'RepeatedExportForecastsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportForecastsResponse'->new($_) } @$_ ] };

declare 'MapStringExportForecastsResponse',
    as HashRef[ExportForecastsResponse()];

declare 'ExportReservationsUsageResponse',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::UsageService::ExportReservationsUsageResponse'];

coerce 'ExportReservationsUsageResponse',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportReservationsUsageResponse'->new($_) };

declare 'RepeatedExportReservationsUsageResponse',
    as ArrayRef[ExportReservationsUsageResponse()];

coerce 'RepeatedExportReservationsUsageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::UsageService::ExportReservationsUsageResponse'->new($_) } @$_ ] };

declare 'MapStringExportReservationsUsageResponse',
    as HashRef[ExportReservationsUsageResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Capacityplanner::V1beta::UsageService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
