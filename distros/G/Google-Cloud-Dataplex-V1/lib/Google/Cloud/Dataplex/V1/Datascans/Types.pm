package Google::Cloud::Dataplex::V1::Datascans::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataScanType',
    as (Int | Str);

declare 'CreateDataScanRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::CreateDataScanRequest'];

coerce 'CreateDataScanRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::CreateDataScanRequest'->new($_) };

declare 'RepeatedCreateDataScanRequest',
    as ArrayRef[CreateDataScanRequest()];

coerce 'RepeatedCreateDataScanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::CreateDataScanRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataScanRequest',
    as HashRef[CreateDataScanRequest()];

declare 'UpdateDataScanRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::UpdateDataScanRequest'];

coerce 'UpdateDataScanRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::UpdateDataScanRequest'->new($_) };

declare 'RepeatedUpdateDataScanRequest',
    as ArrayRef[UpdateDataScanRequest()];

coerce 'RepeatedUpdateDataScanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::UpdateDataScanRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataScanRequest',
    as HashRef[UpdateDataScanRequest()];

declare 'DeleteDataScanRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::DeleteDataScanRequest'];

coerce 'DeleteDataScanRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::DeleteDataScanRequest'->new($_) };

declare 'RepeatedDeleteDataScanRequest',
    as ArrayRef[DeleteDataScanRequest()];

coerce 'RepeatedDeleteDataScanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::DeleteDataScanRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataScanRequest',
    as HashRef[DeleteDataScanRequest()];

declare 'GetDataScanRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::GetDataScanRequest'];

coerce 'GetDataScanRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::GetDataScanRequest'->new($_) };

declare 'RepeatedGetDataScanRequest',
    as ArrayRef[GetDataScanRequest()];

coerce 'RepeatedGetDataScanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::GetDataScanRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataScanRequest',
    as HashRef[GetDataScanRequest()];

declare 'DataScanView',
    as (Int | Str);

declare 'ListDataScansRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::ListDataScansRequest'];

coerce 'ListDataScansRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::ListDataScansRequest'->new($_) };

declare 'RepeatedListDataScansRequest',
    as ArrayRef[ListDataScansRequest()];

coerce 'RepeatedListDataScansRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::ListDataScansRequest'->new($_) } @$_ ] };

declare 'MapStringListDataScansRequest',
    as HashRef[ListDataScansRequest()];

declare 'ListDataScansResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::ListDataScansResponse'];

coerce 'ListDataScansResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::ListDataScansResponse'->new($_) };

declare 'RepeatedListDataScansResponse',
    as ArrayRef[ListDataScansResponse()];

coerce 'RepeatedListDataScansResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::ListDataScansResponse'->new($_) } @$_ ] };

declare 'MapStringListDataScansResponse',
    as HashRef[ListDataScansResponse()];

declare 'RunDataScanRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::RunDataScanRequest'];

coerce 'RunDataScanRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::RunDataScanRequest'->new($_) };

declare 'RepeatedRunDataScanRequest',
    as ArrayRef[RunDataScanRequest()];

coerce 'RepeatedRunDataScanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::RunDataScanRequest'->new($_) } @$_ ] };

declare 'MapStringRunDataScanRequest',
    as HashRef[RunDataScanRequest()];

declare 'RunDataScanResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::RunDataScanResponse'];

coerce 'RunDataScanResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::RunDataScanResponse'->new($_) };

declare 'RepeatedRunDataScanResponse',
    as ArrayRef[RunDataScanResponse()];

coerce 'RepeatedRunDataScanResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::RunDataScanResponse'->new($_) } @$_ ] };

declare 'MapStringRunDataScanResponse',
    as HashRef[RunDataScanResponse()];

declare 'GetDataScanJobRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::GetDataScanJobRequest'];

coerce 'GetDataScanJobRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::GetDataScanJobRequest'->new($_) };

declare 'RepeatedGetDataScanJobRequest',
    as ArrayRef[GetDataScanJobRequest()];

coerce 'RepeatedGetDataScanJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::GetDataScanJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataScanJobRequest',
    as HashRef[GetDataScanJobRequest()];

declare 'DataScanJobView',
    as (Int | Str);

declare 'ListDataScanJobsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::ListDataScanJobsRequest'];

coerce 'ListDataScanJobsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::ListDataScanJobsRequest'->new($_) };

declare 'RepeatedListDataScanJobsRequest',
    as ArrayRef[ListDataScanJobsRequest()];

coerce 'RepeatedListDataScanJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::ListDataScanJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListDataScanJobsRequest',
    as HashRef[ListDataScanJobsRequest()];

declare 'ListDataScanJobsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::ListDataScanJobsResponse'];

coerce 'ListDataScanJobsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::ListDataScanJobsResponse'->new($_) };

declare 'RepeatedListDataScanJobsResponse',
    as ArrayRef[ListDataScanJobsResponse()];

coerce 'RepeatedListDataScanJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::ListDataScanJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListDataScanJobsResponse',
    as HashRef[ListDataScanJobsResponse()];

declare 'CancelDataScanJobRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::CancelDataScanJobRequest'];

coerce 'CancelDataScanJobRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::CancelDataScanJobRequest'->new($_) };

declare 'RepeatedCancelDataScanJobRequest',
    as ArrayRef[CancelDataScanJobRequest()];

coerce 'RepeatedCancelDataScanJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::CancelDataScanJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelDataScanJobRequest',
    as HashRef[CancelDataScanJobRequest()];

declare 'CancelDataScanJobResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::CancelDataScanJobResponse'];

coerce 'CancelDataScanJobResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::CancelDataScanJobResponse'->new($_) };

declare 'RepeatedCancelDataScanJobResponse',
    as ArrayRef[CancelDataScanJobResponse()];

coerce 'RepeatedCancelDataScanJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::CancelDataScanJobResponse'->new($_) } @$_ ] };

declare 'MapStringCancelDataScanJobResponse',
    as HashRef[CancelDataScanJobResponse()];

declare 'GenerateDataQualityRulesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::GenerateDataQualityRulesRequest'];

coerce 'GenerateDataQualityRulesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::GenerateDataQualityRulesRequest'->new($_) };

declare 'RepeatedGenerateDataQualityRulesRequest',
    as ArrayRef[GenerateDataQualityRulesRequest()];

coerce 'RepeatedGenerateDataQualityRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::GenerateDataQualityRulesRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateDataQualityRulesRequest',
    as HashRef[GenerateDataQualityRulesRequest()];

declare 'GenerateDataQualityRulesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::GenerateDataQualityRulesResponse'];

coerce 'GenerateDataQualityRulesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::GenerateDataQualityRulesResponse'->new($_) };

declare 'RepeatedGenerateDataQualityRulesResponse',
    as ArrayRef[GenerateDataQualityRulesResponse()];

coerce 'RepeatedGenerateDataQualityRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::GenerateDataQualityRulesResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateDataQualityRulesResponse',
    as HashRef[GenerateDataQualityRulesResponse()];

declare 'DataScan',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::DataScan'];

coerce 'DataScan',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::DataScan'->new($_) };

declare 'RepeatedDataScan',
    as ArrayRef[DataScan()];

coerce 'RepeatedDataScan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::DataScan'->new($_) } @$_ ] };

declare 'MapStringDataScan',
    as HashRef[DataScan()];

declare 'ExecutionSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::DataScan::ExecutionSpec'];

coerce 'ExecutionSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::DataScan::ExecutionSpec'->new($_) };

declare 'RepeatedExecutionSpec',
    as ArrayRef[ExecutionSpec()];

coerce 'RepeatedExecutionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::DataScan::ExecutionSpec'->new($_) } @$_ ] };

declare 'MapStringExecutionSpec',
    as HashRef[ExecutionSpec()];

declare 'ExecutionStatus',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::DataScan::ExecutionStatus'];

coerce 'ExecutionStatus',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::DataScan::ExecutionStatus'->new($_) };

declare 'RepeatedExecutionStatus',
    as ArrayRef[ExecutionStatus()];

coerce 'RepeatedExecutionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::DataScan::ExecutionStatus'->new($_) } @$_ ] };

declare 'MapStringExecutionStatus',
    as HashRef[ExecutionStatus()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::DataScan::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::DataScan::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::DataScan::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ExecutionIdentity',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity'];

coerce 'ExecutionIdentity',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity'->new($_) };

declare 'RepeatedExecutionIdentity',
    as ArrayRef[ExecutionIdentity()];

coerce 'RepeatedExecutionIdentity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity'->new($_) } @$_ ] };

declare 'MapStringExecutionIdentity',
    as HashRef[ExecutionIdentity()];

declare 'DataplexServiceAgent',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity::DataplexServiceAgent'];

coerce 'DataplexServiceAgent',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity::DataplexServiceAgent'->new($_) };

declare 'RepeatedDataplexServiceAgent',
    as ArrayRef[DataplexServiceAgent()];

coerce 'RepeatedDataplexServiceAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity::DataplexServiceAgent'->new($_) } @$_ ] };

declare 'MapStringDataplexServiceAgent',
    as HashRef[DataplexServiceAgent()];

declare 'UserCredential',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity::UserCredential'];

coerce 'UserCredential',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity::UserCredential'->new($_) };

declare 'RepeatedUserCredential',
    as ArrayRef[UserCredential()];

coerce 'RepeatedUserCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity::UserCredential'->new($_) } @$_ ] };

declare 'MapStringUserCredential',
    as HashRef[UserCredential()];

declare 'ServiceAccount',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::ExecutionIdentity::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'DataScanJob',
    as InstanceOf['Google::Cloud::Dataplex::V1::Datascans::DataScanJob'];

coerce 'DataScanJob',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Datascans::DataScanJob'->new($_) };

declare 'RepeatedDataScanJob',
    as ArrayRef[DataScanJob()];

coerce 'RepeatedDataScanJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Datascans::DataScanJob'->new($_) } @$_ ] };

declare 'MapStringDataScanJob',
    as HashRef[DataScanJob()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Datascans::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
