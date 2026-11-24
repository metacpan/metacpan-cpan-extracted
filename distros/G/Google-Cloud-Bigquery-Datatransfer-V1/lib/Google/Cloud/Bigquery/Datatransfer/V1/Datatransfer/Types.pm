package Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataSourceParameter',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DataSourceParameter'];

coerce 'DataSourceParameter',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DataSourceParameter'->new($_) };

declare 'RepeatedDataSourceParameter',
    as ArrayRef[DataSourceParameter()];

coerce 'RepeatedDataSourceParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DataSourceParameter'->new($_) } @$_ ] };

declare 'MapStringDataSourceParameter',
    as HashRef[DataSourceParameter()];

declare 'Type',
    as (Int | Str);

declare 'DataSource',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DataSource'];

coerce 'DataSource',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DataSource'->new($_) };

declare 'RepeatedDataSource',
    as ArrayRef[DataSource()];

coerce 'RepeatedDataSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DataSource'->new($_) } @$_ ] };

declare 'MapStringDataSource',
    as HashRef[DataSource()];

declare 'AuthorizationType',
    as (Int | Str);

declare 'DataRefreshType',
    as (Int | Str);

declare 'GetDataSourceRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::GetDataSourceRequest'];

coerce 'GetDataSourceRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::GetDataSourceRequest'->new($_) };

declare 'RepeatedGetDataSourceRequest',
    as ArrayRef[GetDataSourceRequest()];

coerce 'RepeatedGetDataSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::GetDataSourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataSourceRequest',
    as HashRef[GetDataSourceRequest()];

declare 'ListDataSourcesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListDataSourcesRequest'];

coerce 'ListDataSourcesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListDataSourcesRequest'->new($_) };

declare 'RepeatedListDataSourcesRequest',
    as ArrayRef[ListDataSourcesRequest()];

coerce 'RepeatedListDataSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListDataSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListDataSourcesRequest',
    as HashRef[ListDataSourcesRequest()];

declare 'ListDataSourcesResponse',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListDataSourcesResponse'];

coerce 'ListDataSourcesResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListDataSourcesResponse'->new($_) };

declare 'RepeatedListDataSourcesResponse',
    as ArrayRef[ListDataSourcesResponse()];

coerce 'RepeatedListDataSourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListDataSourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListDataSourcesResponse',
    as HashRef[ListDataSourcesResponse()];

declare 'CreateTransferConfigRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::CreateTransferConfigRequest'];

coerce 'CreateTransferConfigRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::CreateTransferConfigRequest'->new($_) };

declare 'RepeatedCreateTransferConfigRequest',
    as ArrayRef[CreateTransferConfigRequest()];

coerce 'RepeatedCreateTransferConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::CreateTransferConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTransferConfigRequest',
    as HashRef[CreateTransferConfigRequest()];

declare 'UpdateTransferConfigRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::UpdateTransferConfigRequest'];

coerce 'UpdateTransferConfigRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::UpdateTransferConfigRequest'->new($_) };

declare 'RepeatedUpdateTransferConfigRequest',
    as ArrayRef[UpdateTransferConfigRequest()];

coerce 'RepeatedUpdateTransferConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::UpdateTransferConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTransferConfigRequest',
    as HashRef[UpdateTransferConfigRequest()];

declare 'GetTransferConfigRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::GetTransferConfigRequest'];

coerce 'GetTransferConfigRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::GetTransferConfigRequest'->new($_) };

declare 'RepeatedGetTransferConfigRequest',
    as ArrayRef[GetTransferConfigRequest()];

coerce 'RepeatedGetTransferConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::GetTransferConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetTransferConfigRequest',
    as HashRef[GetTransferConfigRequest()];

declare 'DeleteTransferConfigRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DeleteTransferConfigRequest'];

coerce 'DeleteTransferConfigRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DeleteTransferConfigRequest'->new($_) };

declare 'RepeatedDeleteTransferConfigRequest',
    as ArrayRef[DeleteTransferConfigRequest()];

coerce 'RepeatedDeleteTransferConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DeleteTransferConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTransferConfigRequest',
    as HashRef[DeleteTransferConfigRequest()];

declare 'GetTransferRunRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::GetTransferRunRequest'];

coerce 'GetTransferRunRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::GetTransferRunRequest'->new($_) };

declare 'RepeatedGetTransferRunRequest',
    as ArrayRef[GetTransferRunRequest()];

coerce 'RepeatedGetTransferRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::GetTransferRunRequest'->new($_) } @$_ ] };

declare 'MapStringGetTransferRunRequest',
    as HashRef[GetTransferRunRequest()];

declare 'DeleteTransferRunRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DeleteTransferRunRequest'];

coerce 'DeleteTransferRunRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DeleteTransferRunRequest'->new($_) };

declare 'RepeatedDeleteTransferRunRequest',
    as ArrayRef[DeleteTransferRunRequest()];

coerce 'RepeatedDeleteTransferRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::DeleteTransferRunRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTransferRunRequest',
    as HashRef[DeleteTransferRunRequest()];

declare 'ListTransferConfigsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferConfigsRequest'];

coerce 'ListTransferConfigsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferConfigsRequest'->new($_) };

declare 'RepeatedListTransferConfigsRequest',
    as ArrayRef[ListTransferConfigsRequest()];

coerce 'RepeatedListTransferConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListTransferConfigsRequest',
    as HashRef[ListTransferConfigsRequest()];

declare 'ListTransferConfigsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferConfigsResponse'];

coerce 'ListTransferConfigsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferConfigsResponse'->new($_) };

declare 'RepeatedListTransferConfigsResponse',
    as ArrayRef[ListTransferConfigsResponse()];

coerce 'RepeatedListTransferConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListTransferConfigsResponse',
    as HashRef[ListTransferConfigsResponse()];

declare 'ListTransferRunsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferRunsRequest'];

coerce 'ListTransferRunsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferRunsRequest'->new($_) };

declare 'RepeatedListTransferRunsRequest',
    as ArrayRef[ListTransferRunsRequest()];

coerce 'RepeatedListTransferRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferRunsRequest'->new($_) } @$_ ] };

declare 'MapStringListTransferRunsRequest',
    as HashRef[ListTransferRunsRequest()];

declare 'RunAttempt',
    as (Int | Str);

declare 'ListTransferRunsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferRunsResponse'];

coerce 'ListTransferRunsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferRunsResponse'->new($_) };

declare 'RepeatedListTransferRunsResponse',
    as ArrayRef[ListTransferRunsResponse()];

coerce 'RepeatedListTransferRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferRunsResponse'->new($_) } @$_ ] };

declare 'MapStringListTransferRunsResponse',
    as HashRef[ListTransferRunsResponse()];

declare 'ListTransferLogsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferLogsRequest'];

coerce 'ListTransferLogsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferLogsRequest'->new($_) };

declare 'RepeatedListTransferLogsRequest',
    as ArrayRef[ListTransferLogsRequest()];

coerce 'RepeatedListTransferLogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferLogsRequest'->new($_) } @$_ ] };

declare 'MapStringListTransferLogsRequest',
    as HashRef[ListTransferLogsRequest()];

declare 'ListTransferLogsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferLogsResponse'];

coerce 'ListTransferLogsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferLogsResponse'->new($_) };

declare 'RepeatedListTransferLogsResponse',
    as ArrayRef[ListTransferLogsResponse()];

coerce 'RepeatedListTransferLogsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ListTransferLogsResponse'->new($_) } @$_ ] };

declare 'MapStringListTransferLogsResponse',
    as HashRef[ListTransferLogsResponse()];

declare 'CheckValidCredsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::CheckValidCredsRequest'];

coerce 'CheckValidCredsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::CheckValidCredsRequest'->new($_) };

declare 'RepeatedCheckValidCredsRequest',
    as ArrayRef[CheckValidCredsRequest()];

coerce 'RepeatedCheckValidCredsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::CheckValidCredsRequest'->new($_) } @$_ ] };

declare 'MapStringCheckValidCredsRequest',
    as HashRef[CheckValidCredsRequest()];

declare 'CheckValidCredsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::CheckValidCredsResponse'];

coerce 'CheckValidCredsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::CheckValidCredsResponse'->new($_) };

declare 'RepeatedCheckValidCredsResponse',
    as ArrayRef[CheckValidCredsResponse()];

coerce 'RepeatedCheckValidCredsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::CheckValidCredsResponse'->new($_) } @$_ ] };

declare 'MapStringCheckValidCredsResponse',
    as HashRef[CheckValidCredsResponse()];

declare 'ScheduleTransferRunsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ScheduleTransferRunsRequest'];

coerce 'ScheduleTransferRunsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ScheduleTransferRunsRequest'->new($_) };

declare 'RepeatedScheduleTransferRunsRequest',
    as ArrayRef[ScheduleTransferRunsRequest()];

coerce 'RepeatedScheduleTransferRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ScheduleTransferRunsRequest'->new($_) } @$_ ] };

declare 'MapStringScheduleTransferRunsRequest',
    as HashRef[ScheduleTransferRunsRequest()];

declare 'ScheduleTransferRunsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ScheduleTransferRunsResponse'];

coerce 'ScheduleTransferRunsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ScheduleTransferRunsResponse'->new($_) };

declare 'RepeatedScheduleTransferRunsResponse',
    as ArrayRef[ScheduleTransferRunsResponse()];

coerce 'RepeatedScheduleTransferRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::ScheduleTransferRunsResponse'->new($_) } @$_ ] };

declare 'MapStringScheduleTransferRunsResponse',
    as HashRef[ScheduleTransferRunsResponse()];

declare 'StartManualTransferRunsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::StartManualTransferRunsRequest'];

coerce 'StartManualTransferRunsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::StartManualTransferRunsRequest'->new($_) };

declare 'RepeatedStartManualTransferRunsRequest',
    as ArrayRef[StartManualTransferRunsRequest()];

coerce 'RepeatedStartManualTransferRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::StartManualTransferRunsRequest'->new($_) } @$_ ] };

declare 'MapStringStartManualTransferRunsRequest',
    as HashRef[StartManualTransferRunsRequest()];

declare 'TimeRange',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::StartManualTransferRunsRequest::TimeRange'];

coerce 'TimeRange',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::StartManualTransferRunsRequest::TimeRange'->new($_) };

declare 'RepeatedTimeRange',
    as ArrayRef[TimeRange()];

coerce 'RepeatedTimeRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::StartManualTransferRunsRequest::TimeRange'->new($_) } @$_ ] };

declare 'MapStringTimeRange',
    as HashRef[TimeRange()];

declare 'StartManualTransferRunsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::StartManualTransferRunsResponse'];

coerce 'StartManualTransferRunsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::StartManualTransferRunsResponse'->new($_) };

declare 'RepeatedStartManualTransferRunsResponse',
    as ArrayRef[StartManualTransferRunsResponse()];

coerce 'RepeatedStartManualTransferRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::StartManualTransferRunsResponse'->new($_) } @$_ ] };

declare 'MapStringStartManualTransferRunsResponse',
    as HashRef[StartManualTransferRunsResponse()];

declare 'EnrollDataSourcesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::EnrollDataSourcesRequest'];

coerce 'EnrollDataSourcesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::EnrollDataSourcesRequest'->new($_) };

declare 'RepeatedEnrollDataSourcesRequest',
    as ArrayRef[EnrollDataSourcesRequest()];

coerce 'RepeatedEnrollDataSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::EnrollDataSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringEnrollDataSourcesRequest',
    as HashRef[EnrollDataSourcesRequest()];

declare 'UnenrollDataSourcesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::UnenrollDataSourcesRequest'];

coerce 'UnenrollDataSourcesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::UnenrollDataSourcesRequest'->new($_) };

declare 'RepeatedUnenrollDataSourcesRequest',
    as ArrayRef[UnenrollDataSourcesRequest()];

coerce 'RepeatedUnenrollDataSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::UnenrollDataSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringUnenrollDataSourcesRequest',
    as HashRef[UnenrollDataSourcesRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Datatransfer::V1::Datatransfer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
