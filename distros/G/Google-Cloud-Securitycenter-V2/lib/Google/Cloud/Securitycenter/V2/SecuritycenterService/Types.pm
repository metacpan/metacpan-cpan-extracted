package Google::Cloud::Securitycenter::V2::SecuritycenterService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BatchCreateResourceValueConfigsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsRequest'];

coerce 'BatchCreateResourceValueConfigsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsRequest'->new($_) };

declare 'RepeatedBatchCreateResourceValueConfigsRequest',
    as ArrayRef[BatchCreateResourceValueConfigsRequest()];

coerce 'RepeatedBatchCreateResourceValueConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateResourceValueConfigsRequest',
    as HashRef[BatchCreateResourceValueConfigsRequest()];

declare 'BatchCreateResourceValueConfigsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsResponse'];

coerce 'BatchCreateResourceValueConfigsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsResponse'->new($_) };

declare 'RepeatedBatchCreateResourceValueConfigsResponse',
    as ArrayRef[BatchCreateResourceValueConfigsResponse()];

coerce 'RepeatedBatchCreateResourceValueConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BatchCreateResourceValueConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateResourceValueConfigsResponse',
    as HashRef[BatchCreateResourceValueConfigsResponse()];

declare 'BulkMuteFindingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::BulkMuteFindingsRequest'];

coerce 'BulkMuteFindingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BulkMuteFindingsRequest'->new($_) };

declare 'RepeatedBulkMuteFindingsRequest',
    as ArrayRef[BulkMuteFindingsRequest()];

coerce 'RepeatedBulkMuteFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BulkMuteFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkMuteFindingsRequest',
    as HashRef[BulkMuteFindingsRequest()];

declare 'MuteState',
    as (Int | Str);

declare 'BulkMuteFindingsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::BulkMuteFindingsResponse'];

coerce 'BulkMuteFindingsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BulkMuteFindingsResponse'->new($_) };

declare 'RepeatedBulkMuteFindingsResponse',
    as ArrayRef[BulkMuteFindingsResponse()];

coerce 'RepeatedBulkMuteFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BulkMuteFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkMuteFindingsResponse',
    as HashRef[BulkMuteFindingsResponse()];

declare 'CreateBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateBigQueryExportRequest'];

coerce 'CreateBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateBigQueryExportRequest'->new($_) };

declare 'RepeatedCreateBigQueryExportRequest',
    as ArrayRef[CreateBigQueryExportRequest()];

coerce 'RepeatedCreateBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBigQueryExportRequest',
    as HashRef[CreateBigQueryExportRequest()];

declare 'CreateFindingRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateFindingRequest'];

coerce 'CreateFindingRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateFindingRequest'->new($_) };

declare 'RepeatedCreateFindingRequest',
    as ArrayRef[CreateFindingRequest()];

coerce 'RepeatedCreateFindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateFindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFindingRequest',
    as HashRef[CreateFindingRequest()];

declare 'CreateMuteConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateMuteConfigRequest'];

coerce 'CreateMuteConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateMuteConfigRequest'->new($_) };

declare 'RepeatedCreateMuteConfigRequest',
    as ArrayRef[CreateMuteConfigRequest()];

coerce 'RepeatedCreateMuteConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateMuteConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMuteConfigRequest',
    as HashRef[CreateMuteConfigRequest()];

declare 'CreateNotificationConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateNotificationConfigRequest'];

coerce 'CreateNotificationConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateNotificationConfigRequest'->new($_) };

declare 'RepeatedCreateNotificationConfigRequest',
    as ArrayRef[CreateNotificationConfigRequest()];

coerce 'RepeatedCreateNotificationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateNotificationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNotificationConfigRequest',
    as HashRef[CreateNotificationConfigRequest()];

declare 'CreateResourceValueConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateResourceValueConfigRequest'];

coerce 'CreateResourceValueConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateResourceValueConfigRequest'->new($_) };

declare 'RepeatedCreateResourceValueConfigRequest',
    as ArrayRef[CreateResourceValueConfigRequest()];

coerce 'RepeatedCreateResourceValueConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateResourceValueConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateResourceValueConfigRequest',
    as HashRef[CreateResourceValueConfigRequest()];

declare 'CreateSourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateSourceRequest'];

coerce 'CreateSourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateSourceRequest'->new($_) };

declare 'RepeatedCreateSourceRequest',
    as ArrayRef[CreateSourceRequest()];

coerce 'RepeatedCreateSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::CreateSourceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSourceRequest',
    as HashRef[CreateSourceRequest()];

declare 'DeleteBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteBigQueryExportRequest'];

coerce 'DeleteBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteBigQueryExportRequest'->new($_) };

declare 'RepeatedDeleteBigQueryExportRequest',
    as ArrayRef[DeleteBigQueryExportRequest()];

coerce 'RepeatedDeleteBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBigQueryExportRequest',
    as HashRef[DeleteBigQueryExportRequest()];

declare 'DeleteMuteConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteMuteConfigRequest'];

coerce 'DeleteMuteConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteMuteConfigRequest'->new($_) };

declare 'RepeatedDeleteMuteConfigRequest',
    as ArrayRef[DeleteMuteConfigRequest()];

coerce 'RepeatedDeleteMuteConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteMuteConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMuteConfigRequest',
    as HashRef[DeleteMuteConfigRequest()];

declare 'DeleteNotificationConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteNotificationConfigRequest'];

coerce 'DeleteNotificationConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteNotificationConfigRequest'->new($_) };

declare 'RepeatedDeleteNotificationConfigRequest',
    as ArrayRef[DeleteNotificationConfigRequest()];

coerce 'RepeatedDeleteNotificationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteNotificationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNotificationConfigRequest',
    as HashRef[DeleteNotificationConfigRequest()];

declare 'DeleteResourceValueConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteResourceValueConfigRequest'];

coerce 'DeleteResourceValueConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteResourceValueConfigRequest'->new($_) };

declare 'RepeatedDeleteResourceValueConfigRequest',
    as ArrayRef[DeleteResourceValueConfigRequest()];

coerce 'RepeatedDeleteResourceValueConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::DeleteResourceValueConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteResourceValueConfigRequest',
    as HashRef[DeleteResourceValueConfigRequest()];

declare 'BigQueryDestination',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::BigQueryDestination'];

coerce 'BigQueryDestination',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BigQueryDestination'->new($_) };

declare 'RepeatedBigQueryDestination',
    as ArrayRef[BigQueryDestination()];

coerce 'RepeatedBigQueryDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::BigQueryDestination'->new($_) } @$_ ] };

declare 'MapStringBigQueryDestination',
    as HashRef[BigQueryDestination()];

declare 'ExportFindingsMetadata',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ExportFindingsMetadata'];

coerce 'ExportFindingsMetadata',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ExportFindingsMetadata'->new($_) };

declare 'RepeatedExportFindingsMetadata',
    as ArrayRef[ExportFindingsMetadata()];

coerce 'RepeatedExportFindingsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ExportFindingsMetadata'->new($_) } @$_ ] };

declare 'MapStringExportFindingsMetadata',
    as HashRef[ExportFindingsMetadata()];

declare 'ExportFindingsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ExportFindingsResponse'];

coerce 'ExportFindingsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ExportFindingsResponse'->new($_) };

declare 'RepeatedExportFindingsResponse',
    as ArrayRef[ExportFindingsResponse()];

coerce 'RepeatedExportFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ExportFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringExportFindingsResponse',
    as HashRef[ExportFindingsResponse()];

declare 'GetBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GetBigQueryExportRequest'];

coerce 'GetBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetBigQueryExportRequest'->new($_) };

declare 'RepeatedGetBigQueryExportRequest',
    as ArrayRef[GetBigQueryExportRequest()];

coerce 'RepeatedGetBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringGetBigQueryExportRequest',
    as HashRef[GetBigQueryExportRequest()];

declare 'GetMuteConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GetMuteConfigRequest'];

coerce 'GetMuteConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetMuteConfigRequest'->new($_) };

declare 'RepeatedGetMuteConfigRequest',
    as ArrayRef[GetMuteConfigRequest()];

coerce 'RepeatedGetMuteConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetMuteConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetMuteConfigRequest',
    as HashRef[GetMuteConfigRequest()];

declare 'GetNotificationConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GetNotificationConfigRequest'];

coerce 'GetNotificationConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetNotificationConfigRequest'->new($_) };

declare 'RepeatedGetNotificationConfigRequest',
    as ArrayRef[GetNotificationConfigRequest()];

coerce 'RepeatedGetNotificationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetNotificationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetNotificationConfigRequest',
    as HashRef[GetNotificationConfigRequest()];

declare 'GetResourceValueConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GetResourceValueConfigRequest'];

coerce 'GetResourceValueConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetResourceValueConfigRequest'->new($_) };

declare 'RepeatedGetResourceValueConfigRequest',
    as ArrayRef[GetResourceValueConfigRequest()];

coerce 'RepeatedGetResourceValueConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetResourceValueConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetResourceValueConfigRequest',
    as HashRef[GetResourceValueConfigRequest()];

declare 'GetSourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GetSourceRequest'];

coerce 'GetSourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetSourceRequest'->new($_) };

declare 'RepeatedGetSourceRequest',
    as ArrayRef[GetSourceRequest()];

coerce 'RepeatedGetSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetSourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetSourceRequest',
    as HashRef[GetSourceRequest()];

declare 'GroupFindingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupFindingsRequest'];

coerce 'GroupFindingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupFindingsRequest'->new($_) };

declare 'RepeatedGroupFindingsRequest',
    as ArrayRef[GroupFindingsRequest()];

coerce 'RepeatedGroupFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringGroupFindingsRequest',
    as HashRef[GroupFindingsRequest()];

declare 'GroupFindingsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupFindingsResponse'];

coerce 'GroupFindingsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupFindingsResponse'->new($_) };

declare 'RepeatedGroupFindingsResponse',
    as ArrayRef[GroupFindingsResponse()];

coerce 'RepeatedGroupFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringGroupFindingsResponse',
    as HashRef[GroupFindingsResponse()];

declare 'GroupResult',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupResult'];

coerce 'GroupResult',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupResult'->new($_) };

declare 'RepeatedGroupResult',
    as ArrayRef[GroupResult()];

coerce 'RepeatedGroupResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupResult'->new($_) } @$_ ] };

declare 'MapStringGroupResult',
    as HashRef[GroupResult()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupResult::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupResult::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GroupResult::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'ListAttackPathsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListAttackPathsRequest'];

coerce 'ListAttackPathsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListAttackPathsRequest'->new($_) };

declare 'RepeatedListAttackPathsRequest',
    as ArrayRef[ListAttackPathsRequest()];

coerce 'RepeatedListAttackPathsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListAttackPathsRequest'->new($_) } @$_ ] };

declare 'MapStringListAttackPathsRequest',
    as HashRef[ListAttackPathsRequest()];

declare 'ListAttackPathsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListAttackPathsResponse'];

coerce 'ListAttackPathsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListAttackPathsResponse'->new($_) };

declare 'RepeatedListAttackPathsResponse',
    as ArrayRef[ListAttackPathsResponse()];

coerce 'RepeatedListAttackPathsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListAttackPathsResponse'->new($_) } @$_ ] };

declare 'MapStringListAttackPathsResponse',
    as HashRef[ListAttackPathsResponse()];

declare 'GetSimulationRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GetSimulationRequest'];

coerce 'GetSimulationRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetSimulationRequest'->new($_) };

declare 'RepeatedGetSimulationRequest',
    as ArrayRef[GetSimulationRequest()];

coerce 'RepeatedGetSimulationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetSimulationRequest'->new($_) } @$_ ] };

declare 'MapStringGetSimulationRequest',
    as HashRef[GetSimulationRequest()];

declare 'GetValuedResourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::GetValuedResourceRequest'];

coerce 'GetValuedResourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetValuedResourceRequest'->new($_) };

declare 'RepeatedGetValuedResourceRequest',
    as ArrayRef[GetValuedResourceRequest()];

coerce 'RepeatedGetValuedResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::GetValuedResourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetValuedResourceRequest',
    as HashRef[GetValuedResourceRequest()];

declare 'ListBigQueryExportsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListBigQueryExportsRequest'];

coerce 'ListBigQueryExportsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListBigQueryExportsRequest'->new($_) };

declare 'RepeatedListBigQueryExportsRequest',
    as ArrayRef[ListBigQueryExportsRequest()];

coerce 'RepeatedListBigQueryExportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListBigQueryExportsRequest'->new($_) } @$_ ] };

declare 'MapStringListBigQueryExportsRequest',
    as HashRef[ListBigQueryExportsRequest()];

declare 'ListBigQueryExportsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListBigQueryExportsResponse'];

coerce 'ListBigQueryExportsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListBigQueryExportsResponse'->new($_) };

declare 'RepeatedListBigQueryExportsResponse',
    as ArrayRef[ListBigQueryExportsResponse()];

coerce 'RepeatedListBigQueryExportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListBigQueryExportsResponse'->new($_) } @$_ ] };

declare 'MapStringListBigQueryExportsResponse',
    as HashRef[ListBigQueryExportsResponse()];

declare 'ListFindingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsRequest'];

coerce 'ListFindingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsRequest'->new($_) };

declare 'RepeatedListFindingsRequest',
    as ArrayRef[ListFindingsRequest()];

coerce 'RepeatedListFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListFindingsRequest',
    as HashRef[ListFindingsRequest()];

declare 'ListFindingsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsResponse'];

coerce 'ListFindingsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsResponse'->new($_) };

declare 'RepeatedListFindingsResponse',
    as ArrayRef[ListFindingsResponse()];

coerce 'RepeatedListFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListFindingsResponse',
    as HashRef[ListFindingsResponse()];

declare 'ListFindingsResult',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsResponse::ListFindingsResult'];

coerce 'ListFindingsResult',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsResponse::ListFindingsResult'->new($_) };

declare 'RepeatedListFindingsResult',
    as ArrayRef[ListFindingsResult()];

coerce 'RepeatedListFindingsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsResponse::ListFindingsResult'->new($_) } @$_ ] };

declare 'MapStringListFindingsResult',
    as HashRef[ListFindingsResult()];

declare 'Resource',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsResponse::ListFindingsResult::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsResponse::ListFindingsResult::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListFindingsResponse::ListFindingsResult::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'ListMuteConfigsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListMuteConfigsRequest'];

coerce 'ListMuteConfigsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListMuteConfigsRequest'->new($_) };

declare 'RepeatedListMuteConfigsRequest',
    as ArrayRef[ListMuteConfigsRequest()];

coerce 'RepeatedListMuteConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListMuteConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListMuteConfigsRequest',
    as HashRef[ListMuteConfigsRequest()];

declare 'ListMuteConfigsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListMuteConfigsResponse'];

coerce 'ListMuteConfigsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListMuteConfigsResponse'->new($_) };

declare 'RepeatedListMuteConfigsResponse',
    as ArrayRef[ListMuteConfigsResponse()];

coerce 'RepeatedListMuteConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListMuteConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListMuteConfigsResponse',
    as HashRef[ListMuteConfigsResponse()];

declare 'ListNotificationConfigsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsRequest'];

coerce 'ListNotificationConfigsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsRequest'->new($_) };

declare 'RepeatedListNotificationConfigsRequest',
    as ArrayRef[ListNotificationConfigsRequest()];

coerce 'RepeatedListNotificationConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListNotificationConfigsRequest',
    as HashRef[ListNotificationConfigsRequest()];

declare 'ListNotificationConfigsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsResponse'];

coerce 'ListNotificationConfigsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsResponse'->new($_) };

declare 'RepeatedListNotificationConfigsResponse',
    as ArrayRef[ListNotificationConfigsResponse()];

coerce 'RepeatedListNotificationConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListNotificationConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListNotificationConfigsResponse',
    as HashRef[ListNotificationConfigsResponse()];

declare 'ListResourceValueConfigsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListResourceValueConfigsRequest'];

coerce 'ListResourceValueConfigsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListResourceValueConfigsRequest'->new($_) };

declare 'RepeatedListResourceValueConfigsRequest',
    as ArrayRef[ListResourceValueConfigsRequest()];

coerce 'RepeatedListResourceValueConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListResourceValueConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListResourceValueConfigsRequest',
    as HashRef[ListResourceValueConfigsRequest()];

declare 'ListResourceValueConfigsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListResourceValueConfigsResponse'];

coerce 'ListResourceValueConfigsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListResourceValueConfigsResponse'->new($_) };

declare 'RepeatedListResourceValueConfigsResponse',
    as ArrayRef[ListResourceValueConfigsResponse()];

coerce 'RepeatedListResourceValueConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListResourceValueConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListResourceValueConfigsResponse',
    as HashRef[ListResourceValueConfigsResponse()];

declare 'ListSourcesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListSourcesRequest'];

coerce 'ListSourcesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListSourcesRequest'->new($_) };

declare 'RepeatedListSourcesRequest',
    as ArrayRef[ListSourcesRequest()];

coerce 'RepeatedListSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListSourcesRequest',
    as HashRef[ListSourcesRequest()];

declare 'ListSourcesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListSourcesResponse'];

coerce 'ListSourcesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListSourcesResponse'->new($_) };

declare 'RepeatedListSourcesResponse',
    as ArrayRef[ListSourcesResponse()];

coerce 'RepeatedListSourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListSourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListSourcesResponse',
    as HashRef[ListSourcesResponse()];

declare 'ListValuedResourcesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListValuedResourcesRequest'];

coerce 'ListValuedResourcesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListValuedResourcesRequest'->new($_) };

declare 'RepeatedListValuedResourcesRequest',
    as ArrayRef[ListValuedResourcesRequest()];

coerce 'RepeatedListValuedResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListValuedResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListValuedResourcesRequest',
    as HashRef[ListValuedResourcesRequest()];

declare 'ListValuedResourcesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::ListValuedResourcesResponse'];

coerce 'ListValuedResourcesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListValuedResourcesResponse'->new($_) };

declare 'RepeatedListValuedResourcesResponse',
    as ArrayRef[ListValuedResourcesResponse()];

coerce 'RepeatedListValuedResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::ListValuedResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListValuedResourcesResponse',
    as HashRef[ListValuedResourcesResponse()];

declare 'SetFindingStateRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::SetFindingStateRequest'];

coerce 'SetFindingStateRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::SetFindingStateRequest'->new($_) };

declare 'RepeatedSetFindingStateRequest',
    as ArrayRef[SetFindingStateRequest()];

coerce 'RepeatedSetFindingStateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::SetFindingStateRequest'->new($_) } @$_ ] };

declare 'MapStringSetFindingStateRequest',
    as HashRef[SetFindingStateRequest()];

declare 'SetMuteRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::SetMuteRequest'];

coerce 'SetMuteRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::SetMuteRequest'->new($_) };

declare 'RepeatedSetMuteRequest',
    as ArrayRef[SetMuteRequest()];

coerce 'RepeatedSetMuteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::SetMuteRequest'->new($_) } @$_ ] };

declare 'MapStringSetMuteRequest',
    as HashRef[SetMuteRequest()];

declare 'UpdateBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateBigQueryExportRequest'];

coerce 'UpdateBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateBigQueryExportRequest'->new($_) };

declare 'RepeatedUpdateBigQueryExportRequest',
    as ArrayRef[UpdateBigQueryExportRequest()];

coerce 'RepeatedUpdateBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBigQueryExportRequest',
    as HashRef[UpdateBigQueryExportRequest()];

declare 'UpdateExternalSystemRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateExternalSystemRequest'];

coerce 'UpdateExternalSystemRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateExternalSystemRequest'->new($_) };

declare 'RepeatedUpdateExternalSystemRequest',
    as ArrayRef[UpdateExternalSystemRequest()];

coerce 'RepeatedUpdateExternalSystemRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateExternalSystemRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExternalSystemRequest',
    as HashRef[UpdateExternalSystemRequest()];

declare 'UpdateFindingRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateFindingRequest'];

coerce 'UpdateFindingRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateFindingRequest'->new($_) };

declare 'RepeatedUpdateFindingRequest',
    as ArrayRef[UpdateFindingRequest()];

coerce 'RepeatedUpdateFindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateFindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFindingRequest',
    as HashRef[UpdateFindingRequest()];

declare 'UpdateMuteConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateMuteConfigRequest'];

coerce 'UpdateMuteConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateMuteConfigRequest'->new($_) };

declare 'RepeatedUpdateMuteConfigRequest',
    as ArrayRef[UpdateMuteConfigRequest()];

coerce 'RepeatedUpdateMuteConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateMuteConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMuteConfigRequest',
    as HashRef[UpdateMuteConfigRequest()];

declare 'UpdateNotificationConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateNotificationConfigRequest'];

coerce 'UpdateNotificationConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateNotificationConfigRequest'->new($_) };

declare 'RepeatedUpdateNotificationConfigRequest',
    as ArrayRef[UpdateNotificationConfigRequest()];

coerce 'RepeatedUpdateNotificationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateNotificationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNotificationConfigRequest',
    as HashRef[UpdateNotificationConfigRequest()];

declare 'UpdateResourceValueConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateResourceValueConfigRequest'];

coerce 'UpdateResourceValueConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateResourceValueConfigRequest'->new($_) };

declare 'RepeatedUpdateResourceValueConfigRequest',
    as ArrayRef[UpdateResourceValueConfigRequest()];

coerce 'RepeatedUpdateResourceValueConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateResourceValueConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateResourceValueConfigRequest',
    as HashRef[UpdateResourceValueConfigRequest()];

declare 'UpdateSecurityMarksRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateSecurityMarksRequest'];

coerce 'UpdateSecurityMarksRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateSecurityMarksRequest'->new($_) };

declare 'RepeatedUpdateSecurityMarksRequest',
    as ArrayRef[UpdateSecurityMarksRequest()];

coerce 'RepeatedUpdateSecurityMarksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateSecurityMarksRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSecurityMarksRequest',
    as HashRef[UpdateSecurityMarksRequest()];

declare 'UpdateSourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateSourceRequest'];

coerce 'UpdateSourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateSourceRequest'->new($_) };

declare 'RepeatedUpdateSourceRequest',
    as ArrayRef[UpdateSourceRequest()];

coerce 'RepeatedUpdateSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecuritycenterService::UpdateSourceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSourceRequest',
    as HashRef[UpdateSourceRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::SecuritycenterService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
