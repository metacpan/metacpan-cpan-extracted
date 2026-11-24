package Google::Iam::Admin::V1::Iam::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServiceAccountKeyAlgorithm',
    as (Int | Str);

declare 'ServiceAccountPrivateKeyType',
    as (Int | Str);

declare 'ServiceAccountPublicKeyType',
    as (Int | Str);

declare 'ServiceAccountKeyOrigin',
    as (Int | Str);

declare 'RoleView',
    as (Int | Str);

declare 'ServiceAccount',
    as InstanceOf['Google::Iam::Admin::V1::Iam::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'CreateServiceAccountRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::CreateServiceAccountRequest'];

coerce 'CreateServiceAccountRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::CreateServiceAccountRequest'->new($_) };

declare 'RepeatedCreateServiceAccountRequest',
    as ArrayRef[CreateServiceAccountRequest()];

coerce 'RepeatedCreateServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::CreateServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceAccountRequest',
    as HashRef[CreateServiceAccountRequest()];

declare 'ListServiceAccountsRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::ListServiceAccountsRequest'];

coerce 'ListServiceAccountsRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::ListServiceAccountsRequest'->new($_) };

declare 'RepeatedListServiceAccountsRequest',
    as ArrayRef[ListServiceAccountsRequest()];

coerce 'RepeatedListServiceAccountsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::ListServiceAccountsRequest'->new($_) } @$_ ] };

declare 'MapStringListServiceAccountsRequest',
    as HashRef[ListServiceAccountsRequest()];

declare 'ListServiceAccountsResponse',
    as InstanceOf['Google::Iam::Admin::V1::Iam::ListServiceAccountsResponse'];

coerce 'ListServiceAccountsResponse',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::ListServiceAccountsResponse'->new($_) };

declare 'RepeatedListServiceAccountsResponse',
    as ArrayRef[ListServiceAccountsResponse()];

coerce 'RepeatedListServiceAccountsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::ListServiceAccountsResponse'->new($_) } @$_ ] };

declare 'MapStringListServiceAccountsResponse',
    as HashRef[ListServiceAccountsResponse()];

declare 'GetServiceAccountRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::GetServiceAccountRequest'];

coerce 'GetServiceAccountRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::GetServiceAccountRequest'->new($_) };

declare 'RepeatedGetServiceAccountRequest',
    as ArrayRef[GetServiceAccountRequest()];

coerce 'RepeatedGetServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::GetServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceAccountRequest',
    as HashRef[GetServiceAccountRequest()];

declare 'DeleteServiceAccountRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::DeleteServiceAccountRequest'];

coerce 'DeleteServiceAccountRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::DeleteServiceAccountRequest'->new($_) };

declare 'RepeatedDeleteServiceAccountRequest',
    as ArrayRef[DeleteServiceAccountRequest()];

coerce 'RepeatedDeleteServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::DeleteServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceAccountRequest',
    as HashRef[DeleteServiceAccountRequest()];

declare 'PatchServiceAccountRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::PatchServiceAccountRequest'];

coerce 'PatchServiceAccountRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::PatchServiceAccountRequest'->new($_) };

declare 'RepeatedPatchServiceAccountRequest',
    as ArrayRef[PatchServiceAccountRequest()];

coerce 'RepeatedPatchServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::PatchServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringPatchServiceAccountRequest',
    as HashRef[PatchServiceAccountRequest()];

declare 'UndeleteServiceAccountRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::UndeleteServiceAccountRequest'];

coerce 'UndeleteServiceAccountRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::UndeleteServiceAccountRequest'->new($_) };

declare 'RepeatedUndeleteServiceAccountRequest',
    as ArrayRef[UndeleteServiceAccountRequest()];

coerce 'RepeatedUndeleteServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::UndeleteServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteServiceAccountRequest',
    as HashRef[UndeleteServiceAccountRequest()];

declare 'UndeleteServiceAccountResponse',
    as InstanceOf['Google::Iam::Admin::V1::Iam::UndeleteServiceAccountResponse'];

coerce 'UndeleteServiceAccountResponse',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::UndeleteServiceAccountResponse'->new($_) };

declare 'RepeatedUndeleteServiceAccountResponse',
    as ArrayRef[UndeleteServiceAccountResponse()];

coerce 'RepeatedUndeleteServiceAccountResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::UndeleteServiceAccountResponse'->new($_) } @$_ ] };

declare 'MapStringUndeleteServiceAccountResponse',
    as HashRef[UndeleteServiceAccountResponse()];

declare 'EnableServiceAccountRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::EnableServiceAccountRequest'];

coerce 'EnableServiceAccountRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::EnableServiceAccountRequest'->new($_) };

declare 'RepeatedEnableServiceAccountRequest',
    as ArrayRef[EnableServiceAccountRequest()];

coerce 'RepeatedEnableServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::EnableServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringEnableServiceAccountRequest',
    as HashRef[EnableServiceAccountRequest()];

declare 'DisableServiceAccountRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::DisableServiceAccountRequest'];

coerce 'DisableServiceAccountRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::DisableServiceAccountRequest'->new($_) };

declare 'RepeatedDisableServiceAccountRequest',
    as ArrayRef[DisableServiceAccountRequest()];

coerce 'RepeatedDisableServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::DisableServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringDisableServiceAccountRequest',
    as HashRef[DisableServiceAccountRequest()];

declare 'ListServiceAccountKeysRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::ListServiceAccountKeysRequest'];

coerce 'ListServiceAccountKeysRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::ListServiceAccountKeysRequest'->new($_) };

declare 'RepeatedListServiceAccountKeysRequest',
    as ArrayRef[ListServiceAccountKeysRequest()];

coerce 'RepeatedListServiceAccountKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::ListServiceAccountKeysRequest'->new($_) } @$_ ] };

declare 'MapStringListServiceAccountKeysRequest',
    as HashRef[ListServiceAccountKeysRequest()];

declare 'KeyType',
    as (Int | Str);

declare 'ListServiceAccountKeysResponse',
    as InstanceOf['Google::Iam::Admin::V1::Iam::ListServiceAccountKeysResponse'];

coerce 'ListServiceAccountKeysResponse',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::ListServiceAccountKeysResponse'->new($_) };

declare 'RepeatedListServiceAccountKeysResponse',
    as ArrayRef[ListServiceAccountKeysResponse()];

coerce 'RepeatedListServiceAccountKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::ListServiceAccountKeysResponse'->new($_) } @$_ ] };

declare 'MapStringListServiceAccountKeysResponse',
    as HashRef[ListServiceAccountKeysResponse()];

declare 'GetServiceAccountKeyRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::GetServiceAccountKeyRequest'];

coerce 'GetServiceAccountKeyRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::GetServiceAccountKeyRequest'->new($_) };

declare 'RepeatedGetServiceAccountKeyRequest',
    as ArrayRef[GetServiceAccountKeyRequest()];

coerce 'RepeatedGetServiceAccountKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::GetServiceAccountKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceAccountKeyRequest',
    as HashRef[GetServiceAccountKeyRequest()];

declare 'ServiceAccountKey',
    as InstanceOf['Google::Iam::Admin::V1::Iam::ServiceAccountKey'];

coerce 'ServiceAccountKey',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::ServiceAccountKey'->new($_) };

declare 'RepeatedServiceAccountKey',
    as ArrayRef[ServiceAccountKey()];

coerce 'RepeatedServiceAccountKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::ServiceAccountKey'->new($_) } @$_ ] };

declare 'MapStringServiceAccountKey',
    as HashRef[ServiceAccountKey()];

declare 'CreateServiceAccountKeyRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::CreateServiceAccountKeyRequest'];

coerce 'CreateServiceAccountKeyRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::CreateServiceAccountKeyRequest'->new($_) };

declare 'RepeatedCreateServiceAccountKeyRequest',
    as ArrayRef[CreateServiceAccountKeyRequest()];

coerce 'RepeatedCreateServiceAccountKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::CreateServiceAccountKeyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceAccountKeyRequest',
    as HashRef[CreateServiceAccountKeyRequest()];

declare 'UploadServiceAccountKeyRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::UploadServiceAccountKeyRequest'];

coerce 'UploadServiceAccountKeyRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::UploadServiceAccountKeyRequest'->new($_) };

declare 'RepeatedUploadServiceAccountKeyRequest',
    as ArrayRef[UploadServiceAccountKeyRequest()];

coerce 'RepeatedUploadServiceAccountKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::UploadServiceAccountKeyRequest'->new($_) } @$_ ] };

declare 'MapStringUploadServiceAccountKeyRequest',
    as HashRef[UploadServiceAccountKeyRequest()];

declare 'DeleteServiceAccountKeyRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::DeleteServiceAccountKeyRequest'];

coerce 'DeleteServiceAccountKeyRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::DeleteServiceAccountKeyRequest'->new($_) };

declare 'RepeatedDeleteServiceAccountKeyRequest',
    as ArrayRef[DeleteServiceAccountKeyRequest()];

coerce 'RepeatedDeleteServiceAccountKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::DeleteServiceAccountKeyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceAccountKeyRequest',
    as HashRef[DeleteServiceAccountKeyRequest()];

declare 'DisableServiceAccountKeyRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::DisableServiceAccountKeyRequest'];

coerce 'DisableServiceAccountKeyRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::DisableServiceAccountKeyRequest'->new($_) };

declare 'RepeatedDisableServiceAccountKeyRequest',
    as ArrayRef[DisableServiceAccountKeyRequest()];

coerce 'RepeatedDisableServiceAccountKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::DisableServiceAccountKeyRequest'->new($_) } @$_ ] };

declare 'MapStringDisableServiceAccountKeyRequest',
    as HashRef[DisableServiceAccountKeyRequest()];

declare 'EnableServiceAccountKeyRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::EnableServiceAccountKeyRequest'];

coerce 'EnableServiceAccountKeyRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::EnableServiceAccountKeyRequest'->new($_) };

declare 'RepeatedEnableServiceAccountKeyRequest',
    as ArrayRef[EnableServiceAccountKeyRequest()];

coerce 'RepeatedEnableServiceAccountKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::EnableServiceAccountKeyRequest'->new($_) } @$_ ] };

declare 'MapStringEnableServiceAccountKeyRequest',
    as HashRef[EnableServiceAccountKeyRequest()];

declare 'SignBlobRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::SignBlobRequest'];

coerce 'SignBlobRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::SignBlobRequest'->new($_) };

declare 'RepeatedSignBlobRequest',
    as ArrayRef[SignBlobRequest()];

coerce 'RepeatedSignBlobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::SignBlobRequest'->new($_) } @$_ ] };

declare 'MapStringSignBlobRequest',
    as HashRef[SignBlobRequest()];

declare 'SignBlobResponse',
    as InstanceOf['Google::Iam::Admin::V1::Iam::SignBlobResponse'];

coerce 'SignBlobResponse',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::SignBlobResponse'->new($_) };

declare 'RepeatedSignBlobResponse',
    as ArrayRef[SignBlobResponse()];

coerce 'RepeatedSignBlobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::SignBlobResponse'->new($_) } @$_ ] };

declare 'MapStringSignBlobResponse',
    as HashRef[SignBlobResponse()];

declare 'SignJwtRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::SignJwtRequest'];

coerce 'SignJwtRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::SignJwtRequest'->new($_) };

declare 'RepeatedSignJwtRequest',
    as ArrayRef[SignJwtRequest()];

coerce 'RepeatedSignJwtRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::SignJwtRequest'->new($_) } @$_ ] };

declare 'MapStringSignJwtRequest',
    as HashRef[SignJwtRequest()];

declare 'SignJwtResponse',
    as InstanceOf['Google::Iam::Admin::V1::Iam::SignJwtResponse'];

coerce 'SignJwtResponse',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::SignJwtResponse'->new($_) };

declare 'RepeatedSignJwtResponse',
    as ArrayRef[SignJwtResponse()];

coerce 'RepeatedSignJwtResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::SignJwtResponse'->new($_) } @$_ ] };

declare 'MapStringSignJwtResponse',
    as HashRef[SignJwtResponse()];

declare 'Role',
    as InstanceOf['Google::Iam::Admin::V1::Iam::Role'];

coerce 'Role',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::Role'->new($_) };

declare 'RepeatedRole',
    as ArrayRef[Role()];

coerce 'RepeatedRole',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::Role'->new($_) } @$_ ] };

declare 'MapStringRole',
    as HashRef[Role()];

declare 'RoleLaunchStage',
    as (Int | Str);

declare 'QueryGrantableRolesRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::QueryGrantableRolesRequest'];

coerce 'QueryGrantableRolesRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::QueryGrantableRolesRequest'->new($_) };

declare 'RepeatedQueryGrantableRolesRequest',
    as ArrayRef[QueryGrantableRolesRequest()];

coerce 'RepeatedQueryGrantableRolesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::QueryGrantableRolesRequest'->new($_) } @$_ ] };

declare 'MapStringQueryGrantableRolesRequest',
    as HashRef[QueryGrantableRolesRequest()];

declare 'QueryGrantableRolesResponse',
    as InstanceOf['Google::Iam::Admin::V1::Iam::QueryGrantableRolesResponse'];

coerce 'QueryGrantableRolesResponse',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::QueryGrantableRolesResponse'->new($_) };

declare 'RepeatedQueryGrantableRolesResponse',
    as ArrayRef[QueryGrantableRolesResponse()];

coerce 'RepeatedQueryGrantableRolesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::QueryGrantableRolesResponse'->new($_) } @$_ ] };

declare 'MapStringQueryGrantableRolesResponse',
    as HashRef[QueryGrantableRolesResponse()];

declare 'ListRolesRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::ListRolesRequest'];

coerce 'ListRolesRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::ListRolesRequest'->new($_) };

declare 'RepeatedListRolesRequest',
    as ArrayRef[ListRolesRequest()];

coerce 'RepeatedListRolesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::ListRolesRequest'->new($_) } @$_ ] };

declare 'MapStringListRolesRequest',
    as HashRef[ListRolesRequest()];

declare 'ListRolesResponse',
    as InstanceOf['Google::Iam::Admin::V1::Iam::ListRolesResponse'];

coerce 'ListRolesResponse',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::ListRolesResponse'->new($_) };

declare 'RepeatedListRolesResponse',
    as ArrayRef[ListRolesResponse()];

coerce 'RepeatedListRolesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::ListRolesResponse'->new($_) } @$_ ] };

declare 'MapStringListRolesResponse',
    as HashRef[ListRolesResponse()];

declare 'GetRoleRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::GetRoleRequest'];

coerce 'GetRoleRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::GetRoleRequest'->new($_) };

declare 'RepeatedGetRoleRequest',
    as ArrayRef[GetRoleRequest()];

coerce 'RepeatedGetRoleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::GetRoleRequest'->new($_) } @$_ ] };

declare 'MapStringGetRoleRequest',
    as HashRef[GetRoleRequest()];

declare 'CreateRoleRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::CreateRoleRequest'];

coerce 'CreateRoleRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::CreateRoleRequest'->new($_) };

declare 'RepeatedCreateRoleRequest',
    as ArrayRef[CreateRoleRequest()];

coerce 'RepeatedCreateRoleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::CreateRoleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRoleRequest',
    as HashRef[CreateRoleRequest()];

declare 'UpdateRoleRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::UpdateRoleRequest'];

coerce 'UpdateRoleRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::UpdateRoleRequest'->new($_) };

declare 'RepeatedUpdateRoleRequest',
    as ArrayRef[UpdateRoleRequest()];

coerce 'RepeatedUpdateRoleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::UpdateRoleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRoleRequest',
    as HashRef[UpdateRoleRequest()];

declare 'DeleteRoleRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::DeleteRoleRequest'];

coerce 'DeleteRoleRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::DeleteRoleRequest'->new($_) };

declare 'RepeatedDeleteRoleRequest',
    as ArrayRef[DeleteRoleRequest()];

coerce 'RepeatedDeleteRoleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::DeleteRoleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRoleRequest',
    as HashRef[DeleteRoleRequest()];

declare 'UndeleteRoleRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::UndeleteRoleRequest'];

coerce 'UndeleteRoleRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::UndeleteRoleRequest'->new($_) };

declare 'RepeatedUndeleteRoleRequest',
    as ArrayRef[UndeleteRoleRequest()];

coerce 'RepeatedUndeleteRoleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::UndeleteRoleRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteRoleRequest',
    as HashRef[UndeleteRoleRequest()];

declare 'Permission',
    as InstanceOf['Google::Iam::Admin::V1::Iam::Permission'];

coerce 'Permission',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::Permission'->new($_) };

declare 'RepeatedPermission',
    as ArrayRef[Permission()];

coerce 'RepeatedPermission',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::Permission'->new($_) } @$_ ] };

declare 'MapStringPermission',
    as HashRef[Permission()];

declare 'PermissionLaunchStage',
    as (Int | Str);

declare 'CustomRolesSupportLevel',
    as (Int | Str);

declare 'QueryTestablePermissionsRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::QueryTestablePermissionsRequest'];

coerce 'QueryTestablePermissionsRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::QueryTestablePermissionsRequest'->new($_) };

declare 'RepeatedQueryTestablePermissionsRequest',
    as ArrayRef[QueryTestablePermissionsRequest()];

coerce 'RepeatedQueryTestablePermissionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::QueryTestablePermissionsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryTestablePermissionsRequest',
    as HashRef[QueryTestablePermissionsRequest()];

declare 'QueryTestablePermissionsResponse',
    as InstanceOf['Google::Iam::Admin::V1::Iam::QueryTestablePermissionsResponse'];

coerce 'QueryTestablePermissionsResponse',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::QueryTestablePermissionsResponse'->new($_) };

declare 'RepeatedQueryTestablePermissionsResponse',
    as ArrayRef[QueryTestablePermissionsResponse()];

coerce 'RepeatedQueryTestablePermissionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::QueryTestablePermissionsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryTestablePermissionsResponse',
    as HashRef[QueryTestablePermissionsResponse()];

declare 'QueryAuditableServicesRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::QueryAuditableServicesRequest'];

coerce 'QueryAuditableServicesRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesRequest'->new($_) };

declare 'RepeatedQueryAuditableServicesRequest',
    as ArrayRef[QueryAuditableServicesRequest()];

coerce 'RepeatedQueryAuditableServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesRequest'->new($_) } @$_ ] };

declare 'MapStringQueryAuditableServicesRequest',
    as HashRef[QueryAuditableServicesRequest()];

declare 'QueryAuditableServicesResponse',
    as InstanceOf['Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse'];

coerce 'QueryAuditableServicesResponse',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse'->new($_) };

declare 'RepeatedQueryAuditableServicesResponse',
    as ArrayRef[QueryAuditableServicesResponse()];

coerce 'RepeatedQueryAuditableServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse'->new($_) } @$_ ] };

declare 'MapStringQueryAuditableServicesResponse',
    as HashRef[QueryAuditableServicesResponse()];

declare 'AuditableService',
    as InstanceOf['Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse::AuditableService'];

coerce 'AuditableService',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse::AuditableService'->new($_) };

declare 'RepeatedAuditableService',
    as ArrayRef[AuditableService()];

coerce 'RepeatedAuditableService',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse::AuditableService'->new($_) } @$_ ] };

declare 'MapStringAuditableService',
    as HashRef[AuditableService()];

declare 'LintPolicyRequest',
    as InstanceOf['Google::Iam::Admin::V1::Iam::LintPolicyRequest'];

coerce 'LintPolicyRequest',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::LintPolicyRequest'->new($_) };

declare 'RepeatedLintPolicyRequest',
    as ArrayRef[LintPolicyRequest()];

coerce 'RepeatedLintPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::LintPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringLintPolicyRequest',
    as HashRef[LintPolicyRequest()];

declare 'LintResult',
    as InstanceOf['Google::Iam::Admin::V1::Iam::LintResult'];

coerce 'LintResult',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::LintResult'->new($_) };

declare 'RepeatedLintResult',
    as ArrayRef[LintResult()];

coerce 'RepeatedLintResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::LintResult'->new($_) } @$_ ] };

declare 'MapStringLintResult',
    as HashRef[LintResult()];

declare 'Level',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'LintPolicyResponse',
    as InstanceOf['Google::Iam::Admin::V1::Iam::LintPolicyResponse'];

coerce 'LintPolicyResponse',
    from HashRef, via { 'Google::Iam::Admin::V1::Iam::LintPolicyResponse'->new($_) };

declare 'RepeatedLintPolicyResponse',
    as ArrayRef[LintPolicyResponse()];

coerce 'RepeatedLintPolicyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::Iam::LintPolicyResponse'->new($_) } @$_ ] };

declare 'MapStringLintPolicyResponse',
    as HashRef[LintPolicyResponse()];

1;

__END__

=head1 NAME

Google::Iam::Admin::V1::Iam::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
