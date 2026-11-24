package Google::Cloud::Alloydb::V1beta::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListClustersRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'CreateSecondaryClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::CreateSecondaryClusterRequest'];

coerce 'CreateSecondaryClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::CreateSecondaryClusterRequest'->new($_) };

declare 'RepeatedCreateSecondaryClusterRequest',
    as ArrayRef[CreateSecondaryClusterRequest()];

coerce 'RepeatedCreateSecondaryClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::CreateSecondaryClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSecondaryClusterRequest',
    as HashRef[CreateSecondaryClusterRequest()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'ExportClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ExportClusterRequest'];

coerce 'ExportClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ExportClusterRequest'->new($_) };

declare 'RepeatedExportClusterRequest',
    as ArrayRef[ExportClusterRequest()];

coerce 'RepeatedExportClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ExportClusterRequest'->new($_) } @$_ ] };

declare 'MapStringExportClusterRequest',
    as HashRef[ExportClusterRequest()];

declare 'CsvExportOptions',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ExportClusterRequest::CsvExportOptions'];

coerce 'CsvExportOptions',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ExportClusterRequest::CsvExportOptions'->new($_) };

declare 'RepeatedCsvExportOptions',
    as ArrayRef[CsvExportOptions()];

coerce 'RepeatedCsvExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ExportClusterRequest::CsvExportOptions'->new($_) } @$_ ] };

declare 'MapStringCsvExportOptions',
    as HashRef[CsvExportOptions()];

declare 'SqlExportOptions',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ExportClusterRequest::SqlExportOptions'];

coerce 'SqlExportOptions',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ExportClusterRequest::SqlExportOptions'->new($_) };

declare 'RepeatedSqlExportOptions',
    as ArrayRef[SqlExportOptions()];

coerce 'RepeatedSqlExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ExportClusterRequest::SqlExportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlExportOptions',
    as HashRef[SqlExportOptions()];

declare 'ExportClusterResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ExportClusterResponse'];

coerce 'ExportClusterResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ExportClusterResponse'->new($_) };

declare 'RepeatedExportClusterResponse',
    as ArrayRef[ExportClusterResponse()];

coerce 'RepeatedExportClusterResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ExportClusterResponse'->new($_) } @$_ ] };

declare 'MapStringExportClusterResponse',
    as HashRef[ExportClusterResponse()];

declare 'ImportClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ImportClusterRequest'];

coerce 'ImportClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ImportClusterRequest'->new($_) };

declare 'RepeatedImportClusterRequest',
    as ArrayRef[ImportClusterRequest()];

coerce 'RepeatedImportClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ImportClusterRequest'->new($_) } @$_ ] };

declare 'MapStringImportClusterRequest',
    as HashRef[ImportClusterRequest()];

declare 'SqlImportOptions',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ImportClusterRequest::SqlImportOptions'];

coerce 'SqlImportOptions',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ImportClusterRequest::SqlImportOptions'->new($_) };

declare 'RepeatedSqlImportOptions',
    as ArrayRef[SqlImportOptions()];

coerce 'RepeatedSqlImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ImportClusterRequest::SqlImportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlImportOptions',
    as HashRef[SqlImportOptions()];

declare 'CsvImportOptions',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ImportClusterRequest::CsvImportOptions'];

coerce 'CsvImportOptions',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ImportClusterRequest::CsvImportOptions'->new($_) };

declare 'RepeatedCsvImportOptions',
    as ArrayRef[CsvImportOptions()];

coerce 'RepeatedCsvImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ImportClusterRequest::CsvImportOptions'->new($_) } @$_ ] };

declare 'MapStringCsvImportOptions',
    as HashRef[CsvImportOptions()];

declare 'ImportClusterResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ImportClusterResponse'];

coerce 'ImportClusterResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ImportClusterResponse'->new($_) };

declare 'RepeatedImportClusterResponse',
    as ArrayRef[ImportClusterResponse()];

coerce 'RepeatedImportClusterResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ImportClusterResponse'->new($_) } @$_ ] };

declare 'MapStringImportClusterResponse',
    as HashRef[ImportClusterResponse()];

declare 'UpgradeClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterRequest'];

coerce 'UpgradeClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterRequest'->new($_) };

declare 'RepeatedUpgradeClusterRequest',
    as ArrayRef[UpgradeClusterRequest()];

coerce 'RepeatedUpgradeClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeClusterRequest',
    as HashRef[UpgradeClusterRequest()];

declare 'UpgradeClusterResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse'];

coerce 'UpgradeClusterResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse'->new($_) };

declare 'RepeatedUpgradeClusterResponse',
    as ArrayRef[UpgradeClusterResponse()];

coerce 'RepeatedUpgradeClusterResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse'->new($_) } @$_ ] };

declare 'MapStringUpgradeClusterResponse',
    as HashRef[UpgradeClusterResponse()];

declare 'Status',
    as (Int | Str);

declare 'Stage',
    as (Int | Str);

declare 'StageInfo',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse::StageInfo'];

coerce 'StageInfo',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse::StageInfo'->new($_) };

declare 'RepeatedStageInfo',
    as ArrayRef[StageInfo()];

coerce 'RepeatedStageInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse::StageInfo'->new($_) } @$_ ] };

declare 'MapStringStageInfo',
    as HashRef[StageInfo()];

declare 'InstanceUpgradeDetails',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse::InstanceUpgradeDetails'];

coerce 'InstanceUpgradeDetails',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse::InstanceUpgradeDetails'->new($_) };

declare 'RepeatedInstanceUpgradeDetails',
    as ArrayRef[InstanceUpgradeDetails()];

coerce 'RepeatedInstanceUpgradeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse::InstanceUpgradeDetails'->new($_) } @$_ ] };

declare 'MapStringInstanceUpgradeDetails',
    as HashRef[InstanceUpgradeDetails()];

declare 'ClusterUpgradeDetails',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse::ClusterUpgradeDetails'];

coerce 'ClusterUpgradeDetails',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse::ClusterUpgradeDetails'->new($_) };

declare 'RepeatedClusterUpgradeDetails',
    as ArrayRef[ClusterUpgradeDetails()];

coerce 'RepeatedClusterUpgradeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterResponse::ClusterUpgradeDetails'->new($_) } @$_ ] };

declare 'MapStringClusterUpgradeDetails',
    as HashRef[ClusterUpgradeDetails()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'SwitchoverClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::SwitchoverClusterRequest'];

coerce 'SwitchoverClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::SwitchoverClusterRequest'->new($_) };

declare 'RepeatedSwitchoverClusterRequest',
    as ArrayRef[SwitchoverClusterRequest()];

coerce 'RepeatedSwitchoverClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::SwitchoverClusterRequest'->new($_) } @$_ ] };

declare 'MapStringSwitchoverClusterRequest',
    as HashRef[SwitchoverClusterRequest()];

declare 'PromoteClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::PromoteClusterRequest'];

coerce 'PromoteClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::PromoteClusterRequest'->new($_) };

declare 'RepeatedPromoteClusterRequest',
    as ArrayRef[PromoteClusterRequest()];

coerce 'RepeatedPromoteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::PromoteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringPromoteClusterRequest',
    as HashRef[PromoteClusterRequest()];

declare 'RestoreClusterRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::RestoreClusterRequest'];

coerce 'RestoreClusterRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::RestoreClusterRequest'->new($_) };

declare 'RepeatedRestoreClusterRequest',
    as ArrayRef[RestoreClusterRequest()];

coerce 'RepeatedRestoreClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::RestoreClusterRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreClusterRequest',
    as HashRef[RestoreClusterRequest()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'CreateSecondaryInstanceRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::CreateSecondaryInstanceRequest'];

coerce 'CreateSecondaryInstanceRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::CreateSecondaryInstanceRequest'->new($_) };

declare 'RepeatedCreateSecondaryInstanceRequest',
    as ArrayRef[CreateSecondaryInstanceRequest()];

coerce 'RepeatedCreateSecondaryInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::CreateSecondaryInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSecondaryInstanceRequest',
    as HashRef[CreateSecondaryInstanceRequest()];

declare 'CreateInstanceRequests',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::CreateInstanceRequests'];

coerce 'CreateInstanceRequests',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::CreateInstanceRequests'->new($_) };

declare 'RepeatedCreateInstanceRequests',
    as ArrayRef[CreateInstanceRequests()];

coerce 'RepeatedCreateInstanceRequests',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::CreateInstanceRequests'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequests',
    as HashRef[CreateInstanceRequests()];

declare 'BatchCreateInstancesRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesRequest'];

coerce 'BatchCreateInstancesRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesRequest'->new($_) };

declare 'RepeatedBatchCreateInstancesRequest',
    as ArrayRef[BatchCreateInstancesRequest()];

coerce 'RepeatedBatchCreateInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateInstancesRequest',
    as HashRef[BatchCreateInstancesRequest()];

declare 'BatchCreateInstancesResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesResponse'];

coerce 'BatchCreateInstancesResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesResponse'->new($_) };

declare 'RepeatedBatchCreateInstancesResponse',
    as ArrayRef[BatchCreateInstancesResponse()];

coerce 'RepeatedBatchCreateInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateInstancesResponse',
    as HashRef[BatchCreateInstancesResponse()];

declare 'BatchCreateInstancesMetadata',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesMetadata'];

coerce 'BatchCreateInstancesMetadata',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesMetadata'->new($_) };

declare 'RepeatedBatchCreateInstancesMetadata',
    as ArrayRef[BatchCreateInstancesMetadata()];

coerce 'RepeatedBatchCreateInstancesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchCreateInstancesMetadata',
    as HashRef[BatchCreateInstancesMetadata()];

declare 'InstanceStatusesEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesMetadata::InstanceStatusesEntry'];

coerce 'InstanceStatusesEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesMetadata::InstanceStatusesEntry'->new($_) };

declare 'RepeatedInstanceStatusesEntry',
    as ArrayRef[InstanceStatusesEntry()];

coerce 'RepeatedInstanceStatusesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstancesMetadata::InstanceStatusesEntry'->new($_) } @$_ ] };

declare 'MapStringInstanceStatusesEntry',
    as HashRef[InstanceStatusesEntry()];

declare 'BatchCreateInstanceStatus',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstanceStatus'];

coerce 'BatchCreateInstanceStatus',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstanceStatus'->new($_) };

declare 'RepeatedBatchCreateInstanceStatus',
    as ArrayRef[BatchCreateInstanceStatus()];

coerce 'RepeatedBatchCreateInstanceStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::BatchCreateInstanceStatus'->new($_) } @$_ ] };

declare 'MapStringBatchCreateInstanceStatus',
    as HashRef[BatchCreateInstanceStatus()];

declare 'State',
    as (Int | Str);

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'FailoverInstanceRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::FailoverInstanceRequest'];

coerce 'FailoverInstanceRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::FailoverInstanceRequest'->new($_) };

declare 'RepeatedFailoverInstanceRequest',
    as ArrayRef[FailoverInstanceRequest()];

coerce 'RepeatedFailoverInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::FailoverInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringFailoverInstanceRequest',
    as HashRef[FailoverInstanceRequest()];

declare 'InjectFaultRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::InjectFaultRequest'];

coerce 'InjectFaultRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::InjectFaultRequest'->new($_) };

declare 'RepeatedInjectFaultRequest',
    as ArrayRef[InjectFaultRequest()];

coerce 'RepeatedInjectFaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::InjectFaultRequest'->new($_) } @$_ ] };

declare 'MapStringInjectFaultRequest',
    as HashRef[InjectFaultRequest()];

declare 'FaultType',
    as (Int | Str);

declare 'RestartInstanceRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::RestartInstanceRequest'];

coerce 'RestartInstanceRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::RestartInstanceRequest'->new($_) };

declare 'RepeatedRestartInstanceRequest',
    as ArrayRef[RestartInstanceRequest()];

coerce 'RepeatedRestartInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::RestartInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringRestartInstanceRequest',
    as HashRef[RestartInstanceRequest()];

declare 'ExecuteSqlRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ExecuteSqlRequest'];

coerce 'ExecuteSqlRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ExecuteSqlRequest'->new($_) };

declare 'RepeatedExecuteSqlRequest',
    as ArrayRef[ExecuteSqlRequest()];

coerce 'RepeatedExecuteSqlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ExecuteSqlRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteSqlRequest',
    as HashRef[ExecuteSqlRequest()];

declare 'ExecuteSqlResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ExecuteSqlResponse'];

coerce 'ExecuteSqlResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ExecuteSqlResponse'->new($_) };

declare 'RepeatedExecuteSqlResponse',
    as ArrayRef[ExecuteSqlResponse()];

coerce 'RepeatedExecuteSqlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ExecuteSqlResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteSqlResponse',
    as HashRef[ExecuteSqlResponse()];

declare 'ExecuteSqlMetadata',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ExecuteSqlMetadata'];

coerce 'ExecuteSqlMetadata',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ExecuteSqlMetadata'->new($_) };

declare 'RepeatedExecuteSqlMetadata',
    as ArrayRef[ExecuteSqlMetadata()];

coerce 'RepeatedExecuteSqlMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ExecuteSqlMetadata'->new($_) } @$_ ] };

declare 'MapStringExecuteSqlMetadata',
    as HashRef[ExecuteSqlMetadata()];

declare 'Status',
    as (Int | Str);

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'CreateBackupRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::CreateBackupRequest'];

coerce 'CreateBackupRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::CreateBackupRequest'->new($_) };

declare 'RepeatedCreateBackupRequest',
    as ArrayRef[CreateBackupRequest()];

coerce 'RepeatedCreateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::CreateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupRequest',
    as HashRef[CreateBackupRequest()];

declare 'UpdateBackupRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpdateBackupRequest'];

coerce 'UpdateBackupRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpdateBackupRequest'->new($_) };

declare 'RepeatedUpdateBackupRequest',
    as ArrayRef[UpdateBackupRequest()];

coerce 'RepeatedUpdateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpdateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupRequest',
    as HashRef[UpdateBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'ListSupportedDatabaseFlagsRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListSupportedDatabaseFlagsRequest'];

coerce 'ListSupportedDatabaseFlagsRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListSupportedDatabaseFlagsRequest'->new($_) };

declare 'RepeatedListSupportedDatabaseFlagsRequest',
    as ArrayRef[ListSupportedDatabaseFlagsRequest()];

coerce 'RepeatedListSupportedDatabaseFlagsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListSupportedDatabaseFlagsRequest'->new($_) } @$_ ] };

declare 'MapStringListSupportedDatabaseFlagsRequest',
    as HashRef[ListSupportedDatabaseFlagsRequest()];

declare 'ListSupportedDatabaseFlagsResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListSupportedDatabaseFlagsResponse'];

coerce 'ListSupportedDatabaseFlagsResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListSupportedDatabaseFlagsResponse'->new($_) };

declare 'RepeatedListSupportedDatabaseFlagsResponse',
    as ArrayRef[ListSupportedDatabaseFlagsResponse()];

coerce 'RepeatedListSupportedDatabaseFlagsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListSupportedDatabaseFlagsResponse'->new($_) } @$_ ] };

declare 'MapStringListSupportedDatabaseFlagsResponse',
    as HashRef[ListSupportedDatabaseFlagsResponse()];

declare 'GenerateClientCertificateRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::GenerateClientCertificateRequest'];

coerce 'GenerateClientCertificateRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::GenerateClientCertificateRequest'->new($_) };

declare 'RepeatedGenerateClientCertificateRequest',
    as ArrayRef[GenerateClientCertificateRequest()];

coerce 'RepeatedGenerateClientCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::GenerateClientCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateClientCertificateRequest',
    as HashRef[GenerateClientCertificateRequest()];

declare 'GenerateClientCertificateResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::GenerateClientCertificateResponse'];

coerce 'GenerateClientCertificateResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::GenerateClientCertificateResponse'->new($_) };

declare 'RepeatedGenerateClientCertificateResponse',
    as ArrayRef[GenerateClientCertificateResponse()];

coerce 'RepeatedGenerateClientCertificateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::GenerateClientCertificateResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateClientCertificateResponse',
    as HashRef[GenerateClientCertificateResponse()];

declare 'GetConnectionInfoRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::GetConnectionInfoRequest'];

coerce 'GetConnectionInfoRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::GetConnectionInfoRequest'->new($_) };

declare 'RepeatedGetConnectionInfoRequest',
    as ArrayRef[GetConnectionInfoRequest()];

coerce 'RepeatedGetConnectionInfoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::GetConnectionInfoRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionInfoRequest',
    as HashRef[GetConnectionInfoRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'PromoteClusterStatus',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::PromoteClusterStatus'];

coerce 'PromoteClusterStatus',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::PromoteClusterStatus'->new($_) };

declare 'RepeatedPromoteClusterStatus',
    as ArrayRef[PromoteClusterStatus()];

coerce 'RepeatedPromoteClusterStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::PromoteClusterStatus'->new($_) } @$_ ] };

declare 'MapStringPromoteClusterStatus',
    as HashRef[PromoteClusterStatus()];

declare 'State',
    as (Int | Str);

declare 'UpgradeClusterStatus',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus'];

coerce 'UpgradeClusterStatus',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus'->new($_) };

declare 'RepeatedUpgradeClusterStatus',
    as ArrayRef[UpgradeClusterStatus()];

coerce 'RepeatedUpgradeClusterStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus'->new($_) } @$_ ] };

declare 'MapStringUpgradeClusterStatus',
    as HashRef[UpgradeClusterStatus()];

declare 'StageStatus',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::StageStatus'];

coerce 'StageStatus',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::StageStatus'->new($_) };

declare 'RepeatedStageStatus',
    as ArrayRef[StageStatus()];

coerce 'RepeatedStageStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::StageStatus'->new($_) } @$_ ] };

declare 'MapStringStageStatus',
    as HashRef[StageStatus()];

declare 'StageSchedule',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::StageStatus::StageSchedule'];

coerce 'StageSchedule',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::StageStatus::StageSchedule'->new($_) };

declare 'RepeatedStageSchedule',
    as ArrayRef[StageSchedule()];

coerce 'RepeatedStageSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::StageStatus::StageSchedule'->new($_) } @$_ ] };

declare 'MapStringStageSchedule',
    as HashRef[StageSchedule()];

declare 'ReadPoolInstancesUpgradeStageStatus',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::ReadPoolInstancesUpgradeStageStatus'];

coerce 'ReadPoolInstancesUpgradeStageStatus',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::ReadPoolInstancesUpgradeStageStatus'->new($_) };

declare 'RepeatedReadPoolInstancesUpgradeStageStatus',
    as ArrayRef[ReadPoolInstancesUpgradeStageStatus()];

coerce 'RepeatedReadPoolInstancesUpgradeStageStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::ReadPoolInstancesUpgradeStageStatus'->new($_) } @$_ ] };

declare 'MapStringReadPoolInstancesUpgradeStageStatus',
    as HashRef[ReadPoolInstancesUpgradeStageStatus()];

declare 'Stats',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::ReadPoolInstancesUpgradeStageStatus::Stats'];

coerce 'Stats',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::ReadPoolInstancesUpgradeStageStatus::Stats'->new($_) };

declare 'RepeatedStats',
    as ArrayRef[Stats()];

coerce 'RepeatedStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpgradeClusterStatus::ReadPoolInstancesUpgradeStageStatus::Stats'->new($_) } @$_ ] };

declare 'MapStringStats',
    as HashRef[Stats()];

declare 'ListUsersRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListUsersRequest'];

coerce 'ListUsersRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListUsersRequest'->new($_) };

declare 'RepeatedListUsersRequest',
    as ArrayRef[ListUsersRequest()];

coerce 'RepeatedListUsersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListUsersRequest'->new($_) } @$_ ] };

declare 'MapStringListUsersRequest',
    as HashRef[ListUsersRequest()];

declare 'ListUsersResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListUsersResponse'];

coerce 'ListUsersResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListUsersResponse'->new($_) };

declare 'RepeatedListUsersResponse',
    as ArrayRef[ListUsersResponse()];

coerce 'RepeatedListUsersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListUsersResponse'->new($_) } @$_ ] };

declare 'MapStringListUsersResponse',
    as HashRef[ListUsersResponse()];

declare 'GetUserRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::GetUserRequest'];

coerce 'GetUserRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::GetUserRequest'->new($_) };

declare 'RepeatedGetUserRequest',
    as ArrayRef[GetUserRequest()];

coerce 'RepeatedGetUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::GetUserRequest'->new($_) } @$_ ] };

declare 'MapStringGetUserRequest',
    as HashRef[GetUserRequest()];

declare 'CreateUserRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::CreateUserRequest'];

coerce 'CreateUserRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::CreateUserRequest'->new($_) };

declare 'RepeatedCreateUserRequest',
    as ArrayRef[CreateUserRequest()];

coerce 'RepeatedCreateUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::CreateUserRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUserRequest',
    as HashRef[CreateUserRequest()];

declare 'UpdateUserRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::UpdateUserRequest'];

coerce 'UpdateUserRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::UpdateUserRequest'->new($_) };

declare 'RepeatedUpdateUserRequest',
    as ArrayRef[UpdateUserRequest()];

coerce 'RepeatedUpdateUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::UpdateUserRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUserRequest',
    as HashRef[UpdateUserRequest()];

declare 'DeleteUserRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::DeleteUserRequest'];

coerce 'DeleteUserRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::DeleteUserRequest'->new($_) };

declare 'RepeatedDeleteUserRequest',
    as ArrayRef[DeleteUserRequest()];

coerce 'RepeatedDeleteUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::DeleteUserRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUserRequest',
    as HashRef[DeleteUserRequest()];

declare 'ListDatabasesRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListDatabasesRequest'];

coerce 'ListDatabasesRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListDatabasesRequest'->new($_) };

declare 'RepeatedListDatabasesRequest',
    as ArrayRef[ListDatabasesRequest()];

coerce 'RepeatedListDatabasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListDatabasesRequest'->new($_) } @$_ ] };

declare 'MapStringListDatabasesRequest',
    as HashRef[ListDatabasesRequest()];

declare 'ListDatabasesResponse',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::ListDatabasesResponse'];

coerce 'ListDatabasesResponse',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::ListDatabasesResponse'->new($_) };

declare 'RepeatedListDatabasesResponse',
    as ArrayRef[ListDatabasesResponse()];

coerce 'RepeatedListDatabasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::ListDatabasesResponse'->new($_) } @$_ ] };

declare 'MapStringListDatabasesResponse',
    as HashRef[ListDatabasesResponse()];

declare 'CreateDatabaseRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Service::CreateDatabaseRequest'];

coerce 'CreateDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Service::CreateDatabaseRequest'->new($_) };

declare 'RepeatedCreateDatabaseRequest',
    as ArrayRef[CreateDatabaseRequest()];

coerce 'RepeatedCreateDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Service::CreateDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatabaseRequest',
    as HashRef[CreateDatabaseRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Alloydb::V1beta::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
