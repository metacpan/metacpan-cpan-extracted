package Google::Cloud::Securitycenter::V1::SecuritycenterService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BulkMuteFindingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::BulkMuteFindingsRequest'];

coerce 'BulkMuteFindingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BulkMuteFindingsRequest'->new($_) };

declare 'RepeatedBulkMuteFindingsRequest',
    as ArrayRef[BulkMuteFindingsRequest()];

coerce 'RepeatedBulkMuteFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BulkMuteFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkMuteFindingsRequest',
    as HashRef[BulkMuteFindingsRequest()];

declare 'MuteState',
    as (Int | Str);

declare 'BulkMuteFindingsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::BulkMuteFindingsResponse'];

coerce 'BulkMuteFindingsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BulkMuteFindingsResponse'->new($_) };

declare 'RepeatedBulkMuteFindingsResponse',
    as ArrayRef[BulkMuteFindingsResponse()];

coerce 'RepeatedBulkMuteFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BulkMuteFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkMuteFindingsResponse',
    as HashRef[BulkMuteFindingsResponse()];

declare 'CreateFindingRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateFindingRequest'];

coerce 'CreateFindingRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateFindingRequest'->new($_) };

declare 'RepeatedCreateFindingRequest',
    as ArrayRef[CreateFindingRequest()];

coerce 'RepeatedCreateFindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateFindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFindingRequest',
    as HashRef[CreateFindingRequest()];

declare 'CreateMuteConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateMuteConfigRequest'];

coerce 'CreateMuteConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateMuteConfigRequest'->new($_) };

declare 'RepeatedCreateMuteConfigRequest',
    as ArrayRef[CreateMuteConfigRequest()];

coerce 'RepeatedCreateMuteConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateMuteConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMuteConfigRequest',
    as HashRef[CreateMuteConfigRequest()];

declare 'CreateResourceValueConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateResourceValueConfigRequest'];

coerce 'CreateResourceValueConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateResourceValueConfigRequest'->new($_) };

declare 'RepeatedCreateResourceValueConfigRequest',
    as ArrayRef[CreateResourceValueConfigRequest()];

coerce 'RepeatedCreateResourceValueConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateResourceValueConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateResourceValueConfigRequest',
    as HashRef[CreateResourceValueConfigRequest()];

declare 'BatchCreateResourceValueConfigsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsRequest'];

coerce 'BatchCreateResourceValueConfigsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsRequest'->new($_) };

declare 'RepeatedBatchCreateResourceValueConfigsRequest',
    as ArrayRef[BatchCreateResourceValueConfigsRequest()];

coerce 'RepeatedBatchCreateResourceValueConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateResourceValueConfigsRequest',
    as HashRef[BatchCreateResourceValueConfigsRequest()];

declare 'BatchCreateResourceValueConfigsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsResponse'];

coerce 'BatchCreateResourceValueConfigsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsResponse'->new($_) };

declare 'RepeatedBatchCreateResourceValueConfigsResponse',
    as ArrayRef[BatchCreateResourceValueConfigsResponse()];

coerce 'RepeatedBatchCreateResourceValueConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateResourceValueConfigsResponse',
    as HashRef[BatchCreateResourceValueConfigsResponse()];

declare 'DeleteResourceValueConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteResourceValueConfigRequest'];

coerce 'DeleteResourceValueConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteResourceValueConfigRequest'->new($_) };

declare 'RepeatedDeleteResourceValueConfigRequest',
    as ArrayRef[DeleteResourceValueConfigRequest()];

coerce 'RepeatedDeleteResourceValueConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteResourceValueConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteResourceValueConfigRequest',
    as HashRef[DeleteResourceValueConfigRequest()];

declare 'GetResourceValueConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetResourceValueConfigRequest'];

coerce 'GetResourceValueConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetResourceValueConfigRequest'->new($_) };

declare 'RepeatedGetResourceValueConfigRequest',
    as ArrayRef[GetResourceValueConfigRequest()];

coerce 'RepeatedGetResourceValueConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetResourceValueConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetResourceValueConfigRequest',
    as HashRef[GetResourceValueConfigRequest()];

declare 'ListResourceValueConfigsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListResourceValueConfigsRequest'];

coerce 'ListResourceValueConfigsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListResourceValueConfigsRequest'->new($_) };

declare 'RepeatedListResourceValueConfigsRequest',
    as ArrayRef[ListResourceValueConfigsRequest()];

coerce 'RepeatedListResourceValueConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListResourceValueConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListResourceValueConfigsRequest',
    as HashRef[ListResourceValueConfigsRequest()];

declare 'ListResourceValueConfigsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListResourceValueConfigsResponse'];

coerce 'ListResourceValueConfigsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListResourceValueConfigsResponse'->new($_) };

declare 'RepeatedListResourceValueConfigsResponse',
    as ArrayRef[ListResourceValueConfigsResponse()];

coerce 'RepeatedListResourceValueConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListResourceValueConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListResourceValueConfigsResponse',
    as HashRef[ListResourceValueConfigsResponse()];

declare 'UpdateResourceValueConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateResourceValueConfigRequest'];

coerce 'UpdateResourceValueConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateResourceValueConfigRequest'->new($_) };

declare 'RepeatedUpdateResourceValueConfigRequest',
    as ArrayRef[UpdateResourceValueConfigRequest()];

coerce 'RepeatedUpdateResourceValueConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateResourceValueConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateResourceValueConfigRequest',
    as HashRef[UpdateResourceValueConfigRequest()];

declare 'CreateNotificationConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateNotificationConfigRequest'];

coerce 'CreateNotificationConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateNotificationConfigRequest'->new($_) };

declare 'RepeatedCreateNotificationConfigRequest',
    as ArrayRef[CreateNotificationConfigRequest()];

coerce 'RepeatedCreateNotificationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateNotificationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNotificationConfigRequest',
    as HashRef[CreateNotificationConfigRequest()];

declare 'CreateSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'CreateSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedCreateSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[CreateSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedCreateSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[CreateSecurityHealthAnalyticsCustomModuleRequest()];

declare 'CreateSourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateSourceRequest'];

coerce 'CreateSourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateSourceRequest'->new($_) };

declare 'RepeatedCreateSourceRequest',
    as ArrayRef[CreateSourceRequest()];

coerce 'RepeatedCreateSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateSourceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSourceRequest',
    as HashRef[CreateSourceRequest()];

declare 'DeleteMuteConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteMuteConfigRequest'];

coerce 'DeleteMuteConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteMuteConfigRequest'->new($_) };

declare 'RepeatedDeleteMuteConfigRequest',
    as ArrayRef[DeleteMuteConfigRequest()];

coerce 'RepeatedDeleteMuteConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteMuteConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMuteConfigRequest',
    as HashRef[DeleteMuteConfigRequest()];

declare 'DeleteNotificationConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteNotificationConfigRequest'];

coerce 'DeleteNotificationConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteNotificationConfigRequest'->new($_) };

declare 'RepeatedDeleteNotificationConfigRequest',
    as ArrayRef[DeleteNotificationConfigRequest()];

coerce 'RepeatedDeleteNotificationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteNotificationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNotificationConfigRequest',
    as HashRef[DeleteNotificationConfigRequest()];

declare 'DeleteSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'DeleteSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedDeleteSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[DeleteSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedDeleteSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[DeleteSecurityHealthAnalyticsCustomModuleRequest()];

declare 'GetBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetBigQueryExportRequest'];

coerce 'GetBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetBigQueryExportRequest'->new($_) };

declare 'RepeatedGetBigQueryExportRequest',
    as ArrayRef[GetBigQueryExportRequest()];

coerce 'RepeatedGetBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringGetBigQueryExportRequest',
    as HashRef[GetBigQueryExportRequest()];

declare 'GetMuteConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetMuteConfigRequest'];

coerce 'GetMuteConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetMuteConfigRequest'->new($_) };

declare 'RepeatedGetMuteConfigRequest',
    as ArrayRef[GetMuteConfigRequest()];

coerce 'RepeatedGetMuteConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetMuteConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetMuteConfigRequest',
    as HashRef[GetMuteConfigRequest()];

declare 'GetNotificationConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetNotificationConfigRequest'];

coerce 'GetNotificationConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetNotificationConfigRequest'->new($_) };

declare 'RepeatedGetNotificationConfigRequest',
    as ArrayRef[GetNotificationConfigRequest()];

coerce 'RepeatedGetNotificationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetNotificationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetNotificationConfigRequest',
    as HashRef[GetNotificationConfigRequest()];

declare 'GetOrganizationSettingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetOrganizationSettingsRequest'];

coerce 'GetOrganizationSettingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetOrganizationSettingsRequest'->new($_) };

declare 'RepeatedGetOrganizationSettingsRequest',
    as ArrayRef[GetOrganizationSettingsRequest()];

coerce 'RepeatedGetOrganizationSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetOrganizationSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetOrganizationSettingsRequest',
    as HashRef[GetOrganizationSettingsRequest()];

declare 'GetEffectiveSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'GetEffectiveSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedGetEffectiveSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[GetEffectiveSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedGetEffectiveSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetEffectiveSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[GetEffectiveSecurityHealthAnalyticsCustomModuleRequest()];

declare 'GetSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'GetSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedGetSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[GetSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedGetSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[GetSecurityHealthAnalyticsCustomModuleRequest()];

declare 'GetSourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetSourceRequest'];

coerce 'GetSourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetSourceRequest'->new($_) };

declare 'RepeatedGetSourceRequest',
    as ArrayRef[GetSourceRequest()];

coerce 'RepeatedGetSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetSourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetSourceRequest',
    as HashRef[GetSourceRequest()];

declare 'GroupAssetsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupAssetsRequest'];

coerce 'GroupAssetsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupAssetsRequest'->new($_) };

declare 'RepeatedGroupAssetsRequest',
    as ArrayRef[GroupAssetsRequest()];

coerce 'RepeatedGroupAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringGroupAssetsRequest',
    as HashRef[GroupAssetsRequest()];

declare 'GroupAssetsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupAssetsResponse'];

coerce 'GroupAssetsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupAssetsResponse'->new($_) };

declare 'RepeatedGroupAssetsResponse',
    as ArrayRef[GroupAssetsResponse()];

coerce 'RepeatedGroupAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringGroupAssetsResponse',
    as HashRef[GroupAssetsResponse()];

declare 'GroupFindingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupFindingsRequest'];

coerce 'GroupFindingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupFindingsRequest'->new($_) };

declare 'RepeatedGroupFindingsRequest',
    as ArrayRef[GroupFindingsRequest()];

coerce 'RepeatedGroupFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringGroupFindingsRequest',
    as HashRef[GroupFindingsRequest()];

declare 'GroupFindingsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupFindingsResponse'];

coerce 'GroupFindingsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupFindingsResponse'->new($_) };

declare 'RepeatedGroupFindingsResponse',
    as ArrayRef[GroupFindingsResponse()];

coerce 'RepeatedGroupFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringGroupFindingsResponse',
    as HashRef[GroupFindingsResponse()];

declare 'GroupResult',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupResult'];

coerce 'GroupResult',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupResult'->new($_) };

declare 'RepeatedGroupResult',
    as ArrayRef[GroupResult()];

coerce 'RepeatedGroupResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupResult'->new($_) } @$_ ] };

declare 'MapStringGroupResult',
    as HashRef[GroupResult()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupResult::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupResult::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GroupResult::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'ListDescendantSecurityHealthAnalyticsCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantSecurityHealthAnalyticsCustomModulesRequest'];

coerce 'ListDescendantSecurityHealthAnalyticsCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantSecurityHealthAnalyticsCustomModulesRequest'->new($_) };

declare 'RepeatedListDescendantSecurityHealthAnalyticsCustomModulesRequest',
    as ArrayRef[ListDescendantSecurityHealthAnalyticsCustomModulesRequest()];

coerce 'RepeatedListDescendantSecurityHealthAnalyticsCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantSecurityHealthAnalyticsCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListDescendantSecurityHealthAnalyticsCustomModulesRequest',
    as HashRef[ListDescendantSecurityHealthAnalyticsCustomModulesRequest()];

declare 'ListDescendantSecurityHealthAnalyticsCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantSecurityHealthAnalyticsCustomModulesResponse'];

coerce 'ListDescendantSecurityHealthAnalyticsCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantSecurityHealthAnalyticsCustomModulesResponse'->new($_) };

declare 'RepeatedListDescendantSecurityHealthAnalyticsCustomModulesResponse',
    as ArrayRef[ListDescendantSecurityHealthAnalyticsCustomModulesResponse()];

coerce 'RepeatedListDescendantSecurityHealthAnalyticsCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantSecurityHealthAnalyticsCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListDescendantSecurityHealthAnalyticsCustomModulesResponse',
    as HashRef[ListDescendantSecurityHealthAnalyticsCustomModulesResponse()];

declare 'ListValuedResourcesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListValuedResourcesRequest'];

coerce 'ListValuedResourcesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListValuedResourcesRequest'->new($_) };

declare 'RepeatedListValuedResourcesRequest',
    as ArrayRef[ListValuedResourcesRequest()];

coerce 'RepeatedListValuedResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListValuedResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListValuedResourcesRequest',
    as HashRef[ListValuedResourcesRequest()];

declare 'ListValuedResourcesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListValuedResourcesResponse'];

coerce 'ListValuedResourcesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListValuedResourcesResponse'->new($_) };

declare 'RepeatedListValuedResourcesResponse',
    as ArrayRef[ListValuedResourcesResponse()];

coerce 'RepeatedListValuedResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListValuedResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListValuedResourcesResponse',
    as HashRef[ListValuedResourcesResponse()];

declare 'ListAttackPathsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAttackPathsRequest'];

coerce 'ListAttackPathsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAttackPathsRequest'->new($_) };

declare 'RepeatedListAttackPathsRequest',
    as ArrayRef[ListAttackPathsRequest()];

coerce 'RepeatedListAttackPathsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAttackPathsRequest'->new($_) } @$_ ] };

declare 'MapStringListAttackPathsRequest',
    as HashRef[ListAttackPathsRequest()];

declare 'ListAttackPathsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAttackPathsResponse'];

coerce 'ListAttackPathsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAttackPathsResponse'->new($_) };

declare 'RepeatedListAttackPathsResponse',
    as ArrayRef[ListAttackPathsResponse()];

coerce 'RepeatedListAttackPathsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAttackPathsResponse'->new($_) } @$_ ] };

declare 'MapStringListAttackPathsResponse',
    as HashRef[ListAttackPathsResponse()];

declare 'GetSimulationRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetSimulationRequest'];

coerce 'GetSimulationRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetSimulationRequest'->new($_) };

declare 'RepeatedGetSimulationRequest',
    as ArrayRef[GetSimulationRequest()];

coerce 'RepeatedGetSimulationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetSimulationRequest'->new($_) } @$_ ] };

declare 'MapStringGetSimulationRequest',
    as HashRef[GetSimulationRequest()];

declare 'GetValuedResourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetValuedResourceRequest'];

coerce 'GetValuedResourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetValuedResourceRequest'->new($_) };

declare 'RepeatedGetValuedResourceRequest',
    as ArrayRef[GetValuedResourceRequest()];

coerce 'RepeatedGetValuedResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetValuedResourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetValuedResourceRequest',
    as HashRef[GetValuedResourceRequest()];

declare 'ListMuteConfigsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListMuteConfigsRequest'];

coerce 'ListMuteConfigsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListMuteConfigsRequest'->new($_) };

declare 'RepeatedListMuteConfigsRequest',
    as ArrayRef[ListMuteConfigsRequest()];

coerce 'RepeatedListMuteConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListMuteConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListMuteConfigsRequest',
    as HashRef[ListMuteConfigsRequest()];

declare 'ListMuteConfigsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListMuteConfigsResponse'];

coerce 'ListMuteConfigsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListMuteConfigsResponse'->new($_) };

declare 'RepeatedListMuteConfigsResponse',
    as ArrayRef[ListMuteConfigsResponse()];

coerce 'RepeatedListMuteConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListMuteConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListMuteConfigsResponse',
    as HashRef[ListMuteConfigsResponse()];

declare 'ListNotificationConfigsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListNotificationConfigsRequest'];

coerce 'ListNotificationConfigsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListNotificationConfigsRequest'->new($_) };

declare 'RepeatedListNotificationConfigsRequest',
    as ArrayRef[ListNotificationConfigsRequest()];

coerce 'RepeatedListNotificationConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListNotificationConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListNotificationConfigsRequest',
    as HashRef[ListNotificationConfigsRequest()];

declare 'ListNotificationConfigsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListNotificationConfigsResponse'];

coerce 'ListNotificationConfigsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListNotificationConfigsResponse'->new($_) };

declare 'RepeatedListNotificationConfigsResponse',
    as ArrayRef[ListNotificationConfigsResponse()];

coerce 'RepeatedListNotificationConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListNotificationConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListNotificationConfigsResponse',
    as HashRef[ListNotificationConfigsResponse()];

declare 'ListEffectiveSecurityHealthAnalyticsCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveSecurityHealthAnalyticsCustomModulesRequest'];

coerce 'ListEffectiveSecurityHealthAnalyticsCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveSecurityHealthAnalyticsCustomModulesRequest'->new($_) };

declare 'RepeatedListEffectiveSecurityHealthAnalyticsCustomModulesRequest',
    as ArrayRef[ListEffectiveSecurityHealthAnalyticsCustomModulesRequest()];

coerce 'RepeatedListEffectiveSecurityHealthAnalyticsCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveSecurityHealthAnalyticsCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListEffectiveSecurityHealthAnalyticsCustomModulesRequest',
    as HashRef[ListEffectiveSecurityHealthAnalyticsCustomModulesRequest()];

declare 'ListEffectiveSecurityHealthAnalyticsCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveSecurityHealthAnalyticsCustomModulesResponse'];

coerce 'ListEffectiveSecurityHealthAnalyticsCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveSecurityHealthAnalyticsCustomModulesResponse'->new($_) };

declare 'RepeatedListEffectiveSecurityHealthAnalyticsCustomModulesResponse',
    as ArrayRef[ListEffectiveSecurityHealthAnalyticsCustomModulesResponse()];

coerce 'RepeatedListEffectiveSecurityHealthAnalyticsCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveSecurityHealthAnalyticsCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListEffectiveSecurityHealthAnalyticsCustomModulesResponse',
    as HashRef[ListEffectiveSecurityHealthAnalyticsCustomModulesResponse()];

declare 'ListSecurityHealthAnalyticsCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesRequest'];

coerce 'ListSecurityHealthAnalyticsCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesRequest'->new($_) };

declare 'RepeatedListSecurityHealthAnalyticsCustomModulesRequest',
    as ArrayRef[ListSecurityHealthAnalyticsCustomModulesRequest()];

coerce 'RepeatedListSecurityHealthAnalyticsCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListSecurityHealthAnalyticsCustomModulesRequest',
    as HashRef[ListSecurityHealthAnalyticsCustomModulesRequest()];

declare 'ListSecurityHealthAnalyticsCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesResponse'];

coerce 'ListSecurityHealthAnalyticsCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesResponse'->new($_) };

declare 'RepeatedListSecurityHealthAnalyticsCustomModulesResponse',
    as ArrayRef[ListSecurityHealthAnalyticsCustomModulesResponse()];

coerce 'RepeatedListSecurityHealthAnalyticsCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListSecurityHealthAnalyticsCustomModulesResponse',
    as HashRef[ListSecurityHealthAnalyticsCustomModulesResponse()];

declare 'ListSourcesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSourcesRequest'];

coerce 'ListSourcesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSourcesRequest'->new($_) };

declare 'RepeatedListSourcesRequest',
    as ArrayRef[ListSourcesRequest()];

coerce 'RepeatedListSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListSourcesRequest',
    as HashRef[ListSourcesRequest()];

declare 'ListSourcesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSourcesResponse'];

coerce 'ListSourcesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSourcesResponse'->new($_) };

declare 'RepeatedListSourcesResponse',
    as ArrayRef[ListSourcesResponse()];

coerce 'RepeatedListSourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListSourcesResponse',
    as HashRef[ListSourcesResponse()];

declare 'ListAssetsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAssetsRequest'];

coerce 'ListAssetsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAssetsRequest'->new($_) };

declare 'RepeatedListAssetsRequest',
    as ArrayRef[ListAssetsRequest()];

coerce 'RepeatedListAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssetsRequest',
    as HashRef[ListAssetsRequest()];

declare 'ListAssetsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAssetsResponse'];

coerce 'ListAssetsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAssetsResponse'->new($_) };

declare 'RepeatedListAssetsResponse',
    as ArrayRef[ListAssetsResponse()];

coerce 'RepeatedListAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssetsResponse',
    as HashRef[ListAssetsResponse()];

declare 'ListAssetsResult',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAssetsResponse::ListAssetsResult'];

coerce 'ListAssetsResult',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAssetsResponse::ListAssetsResult'->new($_) };

declare 'RepeatedListAssetsResult',
    as ArrayRef[ListAssetsResult()];

coerce 'RepeatedListAssetsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListAssetsResponse::ListAssetsResult'->new($_) } @$_ ] };

declare 'MapStringListAssetsResult',
    as HashRef[ListAssetsResult()];

declare 'StateChange',
    as (Int | Str);

declare 'ListFindingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsRequest'];

coerce 'ListFindingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsRequest'->new($_) };

declare 'RepeatedListFindingsRequest',
    as ArrayRef[ListFindingsRequest()];

coerce 'RepeatedListFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListFindingsRequest',
    as HashRef[ListFindingsRequest()];

declare 'ListFindingsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse'];

coerce 'ListFindingsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse'->new($_) };

declare 'RepeatedListFindingsResponse',
    as ArrayRef[ListFindingsResponse()];

coerce 'RepeatedListFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListFindingsResponse',
    as HashRef[ListFindingsResponse()];

declare 'ListFindingsResult',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse::ListFindingsResult'];

coerce 'ListFindingsResult',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse::ListFindingsResult'->new($_) };

declare 'RepeatedListFindingsResult',
    as ArrayRef[ListFindingsResult()];

coerce 'RepeatedListFindingsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse::ListFindingsResult'->new($_) } @$_ ] };

declare 'MapStringListFindingsResult',
    as HashRef[ListFindingsResult()];

declare 'StateChange',
    as (Int | Str);

declare 'Resource',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse::ListFindingsResult::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse::ListFindingsResult::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse::ListFindingsResult::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'SetFindingStateRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::SetFindingStateRequest'];

coerce 'SetFindingStateRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SetFindingStateRequest'->new($_) };

declare 'RepeatedSetFindingStateRequest',
    as ArrayRef[SetFindingStateRequest()];

coerce 'RepeatedSetFindingStateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SetFindingStateRequest'->new($_) } @$_ ] };

declare 'MapStringSetFindingStateRequest',
    as HashRef[SetFindingStateRequest()];

declare 'SetMuteRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::SetMuteRequest'];

coerce 'SetMuteRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SetMuteRequest'->new($_) };

declare 'RepeatedSetMuteRequest',
    as ArrayRef[SetMuteRequest()];

coerce 'RepeatedSetMuteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SetMuteRequest'->new($_) } @$_ ] };

declare 'MapStringSetMuteRequest',
    as HashRef[SetMuteRequest()];

declare 'RunAssetDiscoveryRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::RunAssetDiscoveryRequest'];

coerce 'RunAssetDiscoveryRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::RunAssetDiscoveryRequest'->new($_) };

declare 'RepeatedRunAssetDiscoveryRequest',
    as ArrayRef[RunAssetDiscoveryRequest()];

coerce 'RepeatedRunAssetDiscoveryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::RunAssetDiscoveryRequest'->new($_) } @$_ ] };

declare 'MapStringRunAssetDiscoveryRequest',
    as HashRef[RunAssetDiscoveryRequest()];

declare 'SimulateSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'SimulateSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedSimulateSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[SimulateSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedSimulateSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringSimulateSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[SimulateSecurityHealthAnalyticsCustomModuleRequest()];

declare 'SimulatedResource',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleRequest::SimulatedResource'];

coerce 'SimulatedResource',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleRequest::SimulatedResource'->new($_) };

declare 'RepeatedSimulatedResource',
    as ArrayRef[SimulatedResource()];

coerce 'RepeatedSimulatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleRequest::SimulatedResource'->new($_) } @$_ ] };

declare 'MapStringSimulatedResource',
    as HashRef[SimulatedResource()];

declare 'SimulateSecurityHealthAnalyticsCustomModuleResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleResponse'];

coerce 'SimulateSecurityHealthAnalyticsCustomModuleResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleResponse'->new($_) };

declare 'RepeatedSimulateSecurityHealthAnalyticsCustomModuleResponse',
    as ArrayRef[SimulateSecurityHealthAnalyticsCustomModuleResponse()];

coerce 'RepeatedSimulateSecurityHealthAnalyticsCustomModuleResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleResponse'->new($_) } @$_ ] };

declare 'MapStringSimulateSecurityHealthAnalyticsCustomModuleResponse',
    as HashRef[SimulateSecurityHealthAnalyticsCustomModuleResponse()];

declare 'SimulatedResult',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleResponse::SimulatedResult'];

coerce 'SimulatedResult',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleResponse::SimulatedResult'->new($_) };

declare 'RepeatedSimulatedResult',
    as ArrayRef[SimulatedResult()];

coerce 'RepeatedSimulatedResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::SimulateSecurityHealthAnalyticsCustomModuleResponse::SimulatedResult'->new($_) } @$_ ] };

declare 'MapStringSimulatedResult',
    as HashRef[SimulatedResult()];

declare 'UpdateExternalSystemRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateExternalSystemRequest'];

coerce 'UpdateExternalSystemRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateExternalSystemRequest'->new($_) };

declare 'RepeatedUpdateExternalSystemRequest',
    as ArrayRef[UpdateExternalSystemRequest()];

coerce 'RepeatedUpdateExternalSystemRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateExternalSystemRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExternalSystemRequest',
    as HashRef[UpdateExternalSystemRequest()];

declare 'UpdateFindingRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateFindingRequest'];

coerce 'UpdateFindingRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateFindingRequest'->new($_) };

declare 'RepeatedUpdateFindingRequest',
    as ArrayRef[UpdateFindingRequest()];

coerce 'RepeatedUpdateFindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateFindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFindingRequest',
    as HashRef[UpdateFindingRequest()];

declare 'UpdateMuteConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateMuteConfigRequest'];

coerce 'UpdateMuteConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateMuteConfigRequest'->new($_) };

declare 'RepeatedUpdateMuteConfigRequest',
    as ArrayRef[UpdateMuteConfigRequest()];

coerce 'RepeatedUpdateMuteConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateMuteConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMuteConfigRequest',
    as HashRef[UpdateMuteConfigRequest()];

declare 'UpdateNotificationConfigRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateNotificationConfigRequest'];

coerce 'UpdateNotificationConfigRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateNotificationConfigRequest'->new($_) };

declare 'RepeatedUpdateNotificationConfigRequest',
    as ArrayRef[UpdateNotificationConfigRequest()];

coerce 'RepeatedUpdateNotificationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateNotificationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNotificationConfigRequest',
    as HashRef[UpdateNotificationConfigRequest()];

declare 'UpdateOrganizationSettingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateOrganizationSettingsRequest'];

coerce 'UpdateOrganizationSettingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateOrganizationSettingsRequest'->new($_) };

declare 'RepeatedUpdateOrganizationSettingsRequest',
    as ArrayRef[UpdateOrganizationSettingsRequest()];

coerce 'RepeatedUpdateOrganizationSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateOrganizationSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOrganizationSettingsRequest',
    as HashRef[UpdateOrganizationSettingsRequest()];

declare 'UpdateSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'UpdateSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedUpdateSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[UpdateSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedUpdateSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[UpdateSecurityHealthAnalyticsCustomModuleRequest()];

declare 'UpdateSourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSourceRequest'];

coerce 'UpdateSourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSourceRequest'->new($_) };

declare 'RepeatedUpdateSourceRequest',
    as ArrayRef[UpdateSourceRequest()];

coerce 'RepeatedUpdateSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSourceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSourceRequest',
    as HashRef[UpdateSourceRequest()];

declare 'UpdateSecurityMarksRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSecurityMarksRequest'];

coerce 'UpdateSecurityMarksRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSecurityMarksRequest'->new($_) };

declare 'RepeatedUpdateSecurityMarksRequest',
    as ArrayRef[UpdateSecurityMarksRequest()];

coerce 'RepeatedUpdateSecurityMarksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSecurityMarksRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSecurityMarksRequest',
    as HashRef[UpdateSecurityMarksRequest()];

declare 'CreateBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateBigQueryExportRequest'];

coerce 'CreateBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateBigQueryExportRequest'->new($_) };

declare 'RepeatedCreateBigQueryExportRequest',
    as ArrayRef[CreateBigQueryExportRequest()];

coerce 'RepeatedCreateBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBigQueryExportRequest',
    as HashRef[CreateBigQueryExportRequest()];

declare 'UpdateBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateBigQueryExportRequest'];

coerce 'UpdateBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateBigQueryExportRequest'->new($_) };

declare 'RepeatedUpdateBigQueryExportRequest',
    as ArrayRef[UpdateBigQueryExportRequest()];

coerce 'RepeatedUpdateBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBigQueryExportRequest',
    as HashRef[UpdateBigQueryExportRequest()];

declare 'ListBigQueryExportsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListBigQueryExportsRequest'];

coerce 'ListBigQueryExportsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListBigQueryExportsRequest'->new($_) };

declare 'RepeatedListBigQueryExportsRequest',
    as ArrayRef[ListBigQueryExportsRequest()];

coerce 'RepeatedListBigQueryExportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListBigQueryExportsRequest'->new($_) } @$_ ] };

declare 'MapStringListBigQueryExportsRequest',
    as HashRef[ListBigQueryExportsRequest()];

declare 'ListBigQueryExportsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListBigQueryExportsResponse'];

coerce 'ListBigQueryExportsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListBigQueryExportsResponse'->new($_) };

declare 'RepeatedListBigQueryExportsResponse',
    as ArrayRef[ListBigQueryExportsResponse()];

coerce 'RepeatedListBigQueryExportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListBigQueryExportsResponse'->new($_) } @$_ ] };

declare 'MapStringListBigQueryExportsResponse',
    as HashRef[ListBigQueryExportsResponse()];

declare 'DeleteBigQueryExportRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteBigQueryExportRequest'];

coerce 'DeleteBigQueryExportRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteBigQueryExportRequest'->new($_) };

declare 'RepeatedDeleteBigQueryExportRequest',
    as ArrayRef[DeleteBigQueryExportRequest()];

coerce 'RepeatedDeleteBigQueryExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteBigQueryExportRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBigQueryExportRequest',
    as HashRef[DeleteBigQueryExportRequest()];

declare 'CreateEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateEventThreatDetectionCustomModuleRequest'];

coerce 'CreateEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedCreateEventThreatDetectionCustomModuleRequest',
    as ArrayRef[CreateEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedCreateEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEventThreatDetectionCustomModuleRequest',
    as HashRef[CreateEventThreatDetectionCustomModuleRequest()];

declare 'ValidateEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ValidateEventThreatDetectionCustomModuleRequest'];

coerce 'ValidateEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ValidateEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedValidateEventThreatDetectionCustomModuleRequest',
    as ArrayRef[ValidateEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedValidateEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ValidateEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringValidateEventThreatDetectionCustomModuleRequest',
    as HashRef[ValidateEventThreatDetectionCustomModuleRequest()];

declare 'ValidateEventThreatDetectionCustomModuleResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ValidateEventThreatDetectionCustomModuleResponse'];

coerce 'ValidateEventThreatDetectionCustomModuleResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ValidateEventThreatDetectionCustomModuleResponse'->new($_) };

declare 'RepeatedValidateEventThreatDetectionCustomModuleResponse',
    as ArrayRef[ValidateEventThreatDetectionCustomModuleResponse()];

coerce 'RepeatedValidateEventThreatDetectionCustomModuleResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ValidateEventThreatDetectionCustomModuleResponse'->new($_) } @$_ ] };

declare 'MapStringValidateEventThreatDetectionCustomModuleResponse',
    as HashRef[ValidateEventThreatDetectionCustomModuleResponse()];

declare 'DeleteEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteEventThreatDetectionCustomModuleRequest'];

coerce 'DeleteEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedDeleteEventThreatDetectionCustomModuleRequest',
    as ArrayRef[DeleteEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedDeleteEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEventThreatDetectionCustomModuleRequest',
    as HashRef[DeleteEventThreatDetectionCustomModuleRequest()];

declare 'GetEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEventThreatDetectionCustomModuleRequest'];

coerce 'GetEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedGetEventThreatDetectionCustomModuleRequest',
    as ArrayRef[GetEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedGetEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetEventThreatDetectionCustomModuleRequest',
    as HashRef[GetEventThreatDetectionCustomModuleRequest()];

declare 'ListDescendantEventThreatDetectionCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantEventThreatDetectionCustomModulesRequest'];

coerce 'ListDescendantEventThreatDetectionCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantEventThreatDetectionCustomModulesRequest'->new($_) };

declare 'RepeatedListDescendantEventThreatDetectionCustomModulesRequest',
    as ArrayRef[ListDescendantEventThreatDetectionCustomModulesRequest()];

coerce 'RepeatedListDescendantEventThreatDetectionCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantEventThreatDetectionCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListDescendantEventThreatDetectionCustomModulesRequest',
    as HashRef[ListDescendantEventThreatDetectionCustomModulesRequest()];

declare 'ListDescendantEventThreatDetectionCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantEventThreatDetectionCustomModulesResponse'];

coerce 'ListDescendantEventThreatDetectionCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantEventThreatDetectionCustomModulesResponse'->new($_) };

declare 'RepeatedListDescendantEventThreatDetectionCustomModulesResponse',
    as ArrayRef[ListDescendantEventThreatDetectionCustomModulesResponse()];

coerce 'RepeatedListDescendantEventThreatDetectionCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListDescendantEventThreatDetectionCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListDescendantEventThreatDetectionCustomModulesResponse',
    as HashRef[ListDescendantEventThreatDetectionCustomModulesResponse()];

declare 'ListEventThreatDetectionCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesRequest'];

coerce 'ListEventThreatDetectionCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesRequest'->new($_) };

declare 'RepeatedListEventThreatDetectionCustomModulesRequest',
    as ArrayRef[ListEventThreatDetectionCustomModulesRequest()];

coerce 'RepeatedListEventThreatDetectionCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListEventThreatDetectionCustomModulesRequest',
    as HashRef[ListEventThreatDetectionCustomModulesRequest()];

declare 'ListEventThreatDetectionCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesResponse'];

coerce 'ListEventThreatDetectionCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesResponse'->new($_) };

declare 'RepeatedListEventThreatDetectionCustomModulesResponse',
    as ArrayRef[ListEventThreatDetectionCustomModulesResponse()];

coerce 'RepeatedListEventThreatDetectionCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListEventThreatDetectionCustomModulesResponse',
    as HashRef[ListEventThreatDetectionCustomModulesResponse()];

declare 'UpdateEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateEventThreatDetectionCustomModuleRequest'];

coerce 'UpdateEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedUpdateEventThreatDetectionCustomModuleRequest',
    as ArrayRef[UpdateEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedUpdateEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEventThreatDetectionCustomModuleRequest',
    as HashRef[UpdateEventThreatDetectionCustomModuleRequest()];

declare 'GetEffectiveEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveEventThreatDetectionCustomModuleRequest'];

coerce 'GetEffectiveEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedGetEffectiveEventThreatDetectionCustomModuleRequest',
    as ArrayRef[GetEffectiveEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedGetEffectiveEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetEffectiveEventThreatDetectionCustomModuleRequest',
    as HashRef[GetEffectiveEventThreatDetectionCustomModuleRequest()];

declare 'ListEffectiveEventThreatDetectionCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveEventThreatDetectionCustomModulesRequest'];

coerce 'ListEffectiveEventThreatDetectionCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveEventThreatDetectionCustomModulesRequest'->new($_) };

declare 'RepeatedListEffectiveEventThreatDetectionCustomModulesRequest',
    as ArrayRef[ListEffectiveEventThreatDetectionCustomModulesRequest()];

coerce 'RepeatedListEffectiveEventThreatDetectionCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveEventThreatDetectionCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListEffectiveEventThreatDetectionCustomModulesRequest',
    as HashRef[ListEffectiveEventThreatDetectionCustomModulesRequest()];

declare 'ListEffectiveEventThreatDetectionCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveEventThreatDetectionCustomModulesResponse'];

coerce 'ListEffectiveEventThreatDetectionCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveEventThreatDetectionCustomModulesResponse'->new($_) };

declare 'RepeatedListEffectiveEventThreatDetectionCustomModulesResponse',
    as ArrayRef[ListEffectiveEventThreatDetectionCustomModulesResponse()];

coerce 'RepeatedListEffectiveEventThreatDetectionCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEffectiveEventThreatDetectionCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListEffectiveEventThreatDetectionCustomModulesResponse',
    as HashRef[ListEffectiveEventThreatDetectionCustomModulesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::SecuritycenterService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
