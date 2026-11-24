package Google::Cloud::Gkehub::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetScopeNamespaceRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GetScopeNamespaceRequest'];

coerce 'GetScopeNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GetScopeNamespaceRequest'->new($_) };

declare 'RepeatedGetScopeNamespaceRequest',
    as ArrayRef[GetScopeNamespaceRequest()];

coerce 'RepeatedGetScopeNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GetScopeNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringGetScopeNamespaceRequest',
    as HashRef[GetScopeNamespaceRequest()];

declare 'CreateScopeNamespaceRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::CreateScopeNamespaceRequest'];

coerce 'CreateScopeNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::CreateScopeNamespaceRequest'->new($_) };

declare 'RepeatedCreateScopeNamespaceRequest',
    as ArrayRef[CreateScopeNamespaceRequest()];

coerce 'RepeatedCreateScopeNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::CreateScopeNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateScopeNamespaceRequest',
    as HashRef[CreateScopeNamespaceRequest()];

declare 'UpdateScopeNamespaceRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::UpdateScopeNamespaceRequest'];

coerce 'UpdateScopeNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::UpdateScopeNamespaceRequest'->new($_) };

declare 'RepeatedUpdateScopeNamespaceRequest',
    as ArrayRef[UpdateScopeNamespaceRequest()];

coerce 'RepeatedUpdateScopeNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::UpdateScopeNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateScopeNamespaceRequest',
    as HashRef[UpdateScopeNamespaceRequest()];

declare 'DeleteScopeNamespaceRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::DeleteScopeNamespaceRequest'];

coerce 'DeleteScopeNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::DeleteScopeNamespaceRequest'->new($_) };

declare 'RepeatedDeleteScopeNamespaceRequest',
    as ArrayRef[DeleteScopeNamespaceRequest()];

coerce 'RepeatedDeleteScopeNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::DeleteScopeNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteScopeNamespaceRequest',
    as HashRef[DeleteScopeNamespaceRequest()];

declare 'ListScopeNamespacesRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListScopeNamespacesRequest'];

coerce 'ListScopeNamespacesRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListScopeNamespacesRequest'->new($_) };

declare 'RepeatedListScopeNamespacesRequest',
    as ArrayRef[ListScopeNamespacesRequest()];

coerce 'RepeatedListScopeNamespacesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListScopeNamespacesRequest'->new($_) } @$_ ] };

declare 'MapStringListScopeNamespacesRequest',
    as HashRef[ListScopeNamespacesRequest()];

declare 'ListScopeNamespacesResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListScopeNamespacesResponse'];

coerce 'ListScopeNamespacesResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListScopeNamespacesResponse'->new($_) };

declare 'RepeatedListScopeNamespacesResponse',
    as ArrayRef[ListScopeNamespacesResponse()];

coerce 'RepeatedListScopeNamespacesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListScopeNamespacesResponse'->new($_) } @$_ ] };

declare 'MapStringListScopeNamespacesResponse',
    as HashRef[ListScopeNamespacesResponse()];

declare 'GetScopeRBACRoleBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GetScopeRBACRoleBindingRequest'];

coerce 'GetScopeRBACRoleBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GetScopeRBACRoleBindingRequest'->new($_) };

declare 'RepeatedGetScopeRBACRoleBindingRequest',
    as ArrayRef[GetScopeRBACRoleBindingRequest()];

coerce 'RepeatedGetScopeRBACRoleBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GetScopeRBACRoleBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetScopeRBACRoleBindingRequest',
    as HashRef[GetScopeRBACRoleBindingRequest()];

declare 'CreateScopeRBACRoleBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::CreateScopeRBACRoleBindingRequest'];

coerce 'CreateScopeRBACRoleBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::CreateScopeRBACRoleBindingRequest'->new($_) };

declare 'RepeatedCreateScopeRBACRoleBindingRequest',
    as ArrayRef[CreateScopeRBACRoleBindingRequest()];

coerce 'RepeatedCreateScopeRBACRoleBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::CreateScopeRBACRoleBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateScopeRBACRoleBindingRequest',
    as HashRef[CreateScopeRBACRoleBindingRequest()];

declare 'UpdateScopeRBACRoleBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::UpdateScopeRBACRoleBindingRequest'];

coerce 'UpdateScopeRBACRoleBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::UpdateScopeRBACRoleBindingRequest'->new($_) };

declare 'RepeatedUpdateScopeRBACRoleBindingRequest',
    as ArrayRef[UpdateScopeRBACRoleBindingRequest()];

coerce 'RepeatedUpdateScopeRBACRoleBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::UpdateScopeRBACRoleBindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateScopeRBACRoleBindingRequest',
    as HashRef[UpdateScopeRBACRoleBindingRequest()];

declare 'DeleteScopeRBACRoleBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::DeleteScopeRBACRoleBindingRequest'];

coerce 'DeleteScopeRBACRoleBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::DeleteScopeRBACRoleBindingRequest'->new($_) };

declare 'RepeatedDeleteScopeRBACRoleBindingRequest',
    as ArrayRef[DeleteScopeRBACRoleBindingRequest()];

coerce 'RepeatedDeleteScopeRBACRoleBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::DeleteScopeRBACRoleBindingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteScopeRBACRoleBindingRequest',
    as HashRef[DeleteScopeRBACRoleBindingRequest()];

declare 'ListScopeRBACRoleBindingsRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListScopeRBACRoleBindingsRequest'];

coerce 'ListScopeRBACRoleBindingsRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListScopeRBACRoleBindingsRequest'->new($_) };

declare 'RepeatedListScopeRBACRoleBindingsRequest',
    as ArrayRef[ListScopeRBACRoleBindingsRequest()];

coerce 'RepeatedListScopeRBACRoleBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListScopeRBACRoleBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListScopeRBACRoleBindingsRequest',
    as HashRef[ListScopeRBACRoleBindingsRequest()];

declare 'ListScopeRBACRoleBindingsResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListScopeRBACRoleBindingsResponse'];

coerce 'ListScopeRBACRoleBindingsResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListScopeRBACRoleBindingsResponse'->new($_) };

declare 'RepeatedListScopeRBACRoleBindingsResponse',
    as ArrayRef[ListScopeRBACRoleBindingsResponse()];

coerce 'RepeatedListScopeRBACRoleBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListScopeRBACRoleBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListScopeRBACRoleBindingsResponse',
    as HashRef[ListScopeRBACRoleBindingsResponse()];

declare 'GetScopeRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GetScopeRequest'];

coerce 'GetScopeRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GetScopeRequest'->new($_) };

declare 'RepeatedGetScopeRequest',
    as ArrayRef[GetScopeRequest()];

coerce 'RepeatedGetScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GetScopeRequest'->new($_) } @$_ ] };

declare 'MapStringGetScopeRequest',
    as HashRef[GetScopeRequest()];

declare 'CreateScopeRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::CreateScopeRequest'];

coerce 'CreateScopeRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::CreateScopeRequest'->new($_) };

declare 'RepeatedCreateScopeRequest',
    as ArrayRef[CreateScopeRequest()];

coerce 'RepeatedCreateScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::CreateScopeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateScopeRequest',
    as HashRef[CreateScopeRequest()];

declare 'UpdateScopeRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::UpdateScopeRequest'];

coerce 'UpdateScopeRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::UpdateScopeRequest'->new($_) };

declare 'RepeatedUpdateScopeRequest',
    as ArrayRef[UpdateScopeRequest()];

coerce 'RepeatedUpdateScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::UpdateScopeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateScopeRequest',
    as HashRef[UpdateScopeRequest()];

declare 'DeleteScopeRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::DeleteScopeRequest'];

coerce 'DeleteScopeRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::DeleteScopeRequest'->new($_) };

declare 'RepeatedDeleteScopeRequest',
    as ArrayRef[DeleteScopeRequest()];

coerce 'RepeatedDeleteScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::DeleteScopeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteScopeRequest',
    as HashRef[DeleteScopeRequest()];

declare 'ListScopesRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListScopesRequest'];

coerce 'ListScopesRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListScopesRequest'->new($_) };

declare 'RepeatedListScopesRequest',
    as ArrayRef[ListScopesRequest()];

coerce 'RepeatedListScopesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListScopesRequest'->new($_) } @$_ ] };

declare 'MapStringListScopesRequest',
    as HashRef[ListScopesRequest()];

declare 'ListScopesResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListScopesResponse'];

coerce 'ListScopesResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListScopesResponse'->new($_) };

declare 'RepeatedListScopesResponse',
    as ArrayRef[ListScopesResponse()];

coerce 'RepeatedListScopesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListScopesResponse'->new($_) } @$_ ] };

declare 'MapStringListScopesResponse',
    as HashRef[ListScopesResponse()];

declare 'ListPermittedScopesRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListPermittedScopesRequest'];

coerce 'ListPermittedScopesRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListPermittedScopesRequest'->new($_) };

declare 'RepeatedListPermittedScopesRequest',
    as ArrayRef[ListPermittedScopesRequest()];

coerce 'RepeatedListPermittedScopesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListPermittedScopesRequest'->new($_) } @$_ ] };

declare 'MapStringListPermittedScopesRequest',
    as HashRef[ListPermittedScopesRequest()];

declare 'ListPermittedScopesResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListPermittedScopesResponse'];

coerce 'ListPermittedScopesResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListPermittedScopesResponse'->new($_) };

declare 'RepeatedListPermittedScopesResponse',
    as ArrayRef[ListPermittedScopesResponse()];

coerce 'RepeatedListPermittedScopesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListPermittedScopesResponse'->new($_) } @$_ ] };

declare 'MapStringListPermittedScopesResponse',
    as HashRef[ListPermittedScopesResponse()];

declare 'GetMembershipBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GetMembershipBindingRequest'];

coerce 'GetMembershipBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GetMembershipBindingRequest'->new($_) };

declare 'RepeatedGetMembershipBindingRequest',
    as ArrayRef[GetMembershipBindingRequest()];

coerce 'RepeatedGetMembershipBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GetMembershipBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetMembershipBindingRequest',
    as HashRef[GetMembershipBindingRequest()];

declare 'CreateMembershipBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::CreateMembershipBindingRequest'];

coerce 'CreateMembershipBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::CreateMembershipBindingRequest'->new($_) };

declare 'RepeatedCreateMembershipBindingRequest',
    as ArrayRef[CreateMembershipBindingRequest()];

coerce 'RepeatedCreateMembershipBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::CreateMembershipBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMembershipBindingRequest',
    as HashRef[CreateMembershipBindingRequest()];

declare 'UpdateMembershipBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::UpdateMembershipBindingRequest'];

coerce 'UpdateMembershipBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::UpdateMembershipBindingRequest'->new($_) };

declare 'RepeatedUpdateMembershipBindingRequest',
    as ArrayRef[UpdateMembershipBindingRequest()];

coerce 'RepeatedUpdateMembershipBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::UpdateMembershipBindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMembershipBindingRequest',
    as HashRef[UpdateMembershipBindingRequest()];

declare 'DeleteMembershipBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::DeleteMembershipBindingRequest'];

coerce 'DeleteMembershipBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::DeleteMembershipBindingRequest'->new($_) };

declare 'RepeatedDeleteMembershipBindingRequest',
    as ArrayRef[DeleteMembershipBindingRequest()];

coerce 'RepeatedDeleteMembershipBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::DeleteMembershipBindingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMembershipBindingRequest',
    as HashRef[DeleteMembershipBindingRequest()];

declare 'ListMembershipBindingsRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListMembershipBindingsRequest'];

coerce 'ListMembershipBindingsRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListMembershipBindingsRequest'->new($_) };

declare 'RepeatedListMembershipBindingsRequest',
    as ArrayRef[ListMembershipBindingsRequest()];

coerce 'RepeatedListMembershipBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListMembershipBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListMembershipBindingsRequest',
    as HashRef[ListMembershipBindingsRequest()];

declare 'ListMembershipBindingsResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListMembershipBindingsResponse'];

coerce 'ListMembershipBindingsResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListMembershipBindingsResponse'->new($_) };

declare 'RepeatedListMembershipBindingsResponse',
    as ArrayRef[ListMembershipBindingsResponse()];

coerce 'RepeatedListMembershipBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListMembershipBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListMembershipBindingsResponse',
    as HashRef[ListMembershipBindingsResponse()];

declare 'ListMembershipsRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListMembershipsRequest'];

coerce 'ListMembershipsRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListMembershipsRequest'->new($_) };

declare 'RepeatedListMembershipsRequest',
    as ArrayRef[ListMembershipsRequest()];

coerce 'RepeatedListMembershipsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListMembershipsRequest'->new($_) } @$_ ] };

declare 'MapStringListMembershipsRequest',
    as HashRef[ListMembershipsRequest()];

declare 'GetMembershipRBACRoleBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GetMembershipRBACRoleBindingRequest'];

coerce 'GetMembershipRBACRoleBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GetMembershipRBACRoleBindingRequest'->new($_) };

declare 'RepeatedGetMembershipRBACRoleBindingRequest',
    as ArrayRef[GetMembershipRBACRoleBindingRequest()];

coerce 'RepeatedGetMembershipRBACRoleBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GetMembershipRBACRoleBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetMembershipRBACRoleBindingRequest',
    as HashRef[GetMembershipRBACRoleBindingRequest()];

declare 'CreateMembershipRBACRoleBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::CreateMembershipRBACRoleBindingRequest'];

coerce 'CreateMembershipRBACRoleBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::CreateMembershipRBACRoleBindingRequest'->new($_) };

declare 'RepeatedCreateMembershipRBACRoleBindingRequest',
    as ArrayRef[CreateMembershipRBACRoleBindingRequest()];

coerce 'RepeatedCreateMembershipRBACRoleBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::CreateMembershipRBACRoleBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMembershipRBACRoleBindingRequest',
    as HashRef[CreateMembershipRBACRoleBindingRequest()];

declare 'UpdateMembershipRBACRoleBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::UpdateMembershipRBACRoleBindingRequest'];

coerce 'UpdateMembershipRBACRoleBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::UpdateMembershipRBACRoleBindingRequest'->new($_) };

declare 'RepeatedUpdateMembershipRBACRoleBindingRequest',
    as ArrayRef[UpdateMembershipRBACRoleBindingRequest()];

coerce 'RepeatedUpdateMembershipRBACRoleBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::UpdateMembershipRBACRoleBindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMembershipRBACRoleBindingRequest',
    as HashRef[UpdateMembershipRBACRoleBindingRequest()];

declare 'DeleteMembershipRBACRoleBindingRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::DeleteMembershipRBACRoleBindingRequest'];

coerce 'DeleteMembershipRBACRoleBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::DeleteMembershipRBACRoleBindingRequest'->new($_) };

declare 'RepeatedDeleteMembershipRBACRoleBindingRequest',
    as ArrayRef[DeleteMembershipRBACRoleBindingRequest()];

coerce 'RepeatedDeleteMembershipRBACRoleBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::DeleteMembershipRBACRoleBindingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMembershipRBACRoleBindingRequest',
    as HashRef[DeleteMembershipRBACRoleBindingRequest()];

declare 'ListMembershipRBACRoleBindingsRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListMembershipRBACRoleBindingsRequest'];

coerce 'ListMembershipRBACRoleBindingsRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListMembershipRBACRoleBindingsRequest'->new($_) };

declare 'RepeatedListMembershipRBACRoleBindingsRequest',
    as ArrayRef[ListMembershipRBACRoleBindingsRequest()];

coerce 'RepeatedListMembershipRBACRoleBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListMembershipRBACRoleBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListMembershipRBACRoleBindingsRequest',
    as HashRef[ListMembershipRBACRoleBindingsRequest()];

declare 'ListMembershipRBACRoleBindingsResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListMembershipRBACRoleBindingsResponse'];

coerce 'ListMembershipRBACRoleBindingsResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListMembershipRBACRoleBindingsResponse'->new($_) };

declare 'RepeatedListMembershipRBACRoleBindingsResponse',
    as ArrayRef[ListMembershipRBACRoleBindingsResponse()];

coerce 'RepeatedListMembershipRBACRoleBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListMembershipRBACRoleBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListMembershipRBACRoleBindingsResponse',
    as HashRef[ListMembershipRBACRoleBindingsResponse()];

declare 'GenerateMembershipRBACRoleBindingYAMLRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GenerateMembershipRBACRoleBindingYAMLRequest'];

coerce 'GenerateMembershipRBACRoleBindingYAMLRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GenerateMembershipRBACRoleBindingYAMLRequest'->new($_) };

declare 'RepeatedGenerateMembershipRBACRoleBindingYAMLRequest',
    as ArrayRef[GenerateMembershipRBACRoleBindingYAMLRequest()];

coerce 'RepeatedGenerateMembershipRBACRoleBindingYAMLRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GenerateMembershipRBACRoleBindingYAMLRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateMembershipRBACRoleBindingYAMLRequest',
    as HashRef[GenerateMembershipRBACRoleBindingYAMLRequest()];

declare 'GenerateMembershipRBACRoleBindingYAMLResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GenerateMembershipRBACRoleBindingYAMLResponse'];

coerce 'GenerateMembershipRBACRoleBindingYAMLResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GenerateMembershipRBACRoleBindingYAMLResponse'->new($_) };

declare 'RepeatedGenerateMembershipRBACRoleBindingYAMLResponse',
    as ArrayRef[GenerateMembershipRBACRoleBindingYAMLResponse()];

coerce 'RepeatedGenerateMembershipRBACRoleBindingYAMLResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GenerateMembershipRBACRoleBindingYAMLResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateMembershipRBACRoleBindingYAMLResponse',
    as HashRef[GenerateMembershipRBACRoleBindingYAMLResponse()];

declare 'ListMembershipsResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListMembershipsResponse'];

coerce 'ListMembershipsResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListMembershipsResponse'->new($_) };

declare 'RepeatedListMembershipsResponse',
    as ArrayRef[ListMembershipsResponse()];

coerce 'RepeatedListMembershipsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListMembershipsResponse'->new($_) } @$_ ] };

declare 'MapStringListMembershipsResponse',
    as HashRef[ListMembershipsResponse()];

declare 'GetMembershipRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GetMembershipRequest'];

coerce 'GetMembershipRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GetMembershipRequest'->new($_) };

declare 'RepeatedGetMembershipRequest',
    as ArrayRef[GetMembershipRequest()];

coerce 'RepeatedGetMembershipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GetMembershipRequest'->new($_) } @$_ ] };

declare 'MapStringGetMembershipRequest',
    as HashRef[GetMembershipRequest()];

declare 'ListBoundMembershipsRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListBoundMembershipsRequest'];

coerce 'ListBoundMembershipsRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListBoundMembershipsRequest'->new($_) };

declare 'RepeatedListBoundMembershipsRequest',
    as ArrayRef[ListBoundMembershipsRequest()];

coerce 'RepeatedListBoundMembershipsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListBoundMembershipsRequest'->new($_) } @$_ ] };

declare 'MapStringListBoundMembershipsRequest',
    as HashRef[ListBoundMembershipsRequest()];

declare 'ListBoundMembershipsResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListBoundMembershipsResponse'];

coerce 'ListBoundMembershipsResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListBoundMembershipsResponse'->new($_) };

declare 'RepeatedListBoundMembershipsResponse',
    as ArrayRef[ListBoundMembershipsResponse()];

coerce 'RepeatedListBoundMembershipsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListBoundMembershipsResponse'->new($_) } @$_ ] };

declare 'MapStringListBoundMembershipsResponse',
    as HashRef[ListBoundMembershipsResponse()];

declare 'CreateMembershipRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::CreateMembershipRequest'];

coerce 'CreateMembershipRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::CreateMembershipRequest'->new($_) };

declare 'RepeatedCreateMembershipRequest',
    as ArrayRef[CreateMembershipRequest()];

coerce 'RepeatedCreateMembershipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::CreateMembershipRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMembershipRequest',
    as HashRef[CreateMembershipRequest()];

declare 'DeleteMembershipRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::DeleteMembershipRequest'];

coerce 'DeleteMembershipRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::DeleteMembershipRequest'->new($_) };

declare 'RepeatedDeleteMembershipRequest',
    as ArrayRef[DeleteMembershipRequest()];

coerce 'RepeatedDeleteMembershipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::DeleteMembershipRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMembershipRequest',
    as HashRef[DeleteMembershipRequest()];

declare 'UpdateMembershipRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::UpdateMembershipRequest'];

coerce 'UpdateMembershipRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::UpdateMembershipRequest'->new($_) };

declare 'RepeatedUpdateMembershipRequest',
    as ArrayRef[UpdateMembershipRequest()];

coerce 'RepeatedUpdateMembershipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::UpdateMembershipRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMembershipRequest',
    as HashRef[UpdateMembershipRequest()];

declare 'GenerateConnectManifestRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GenerateConnectManifestRequest'];

coerce 'GenerateConnectManifestRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GenerateConnectManifestRequest'->new($_) };

declare 'RepeatedGenerateConnectManifestRequest',
    as ArrayRef[GenerateConnectManifestRequest()];

coerce 'RepeatedGenerateConnectManifestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GenerateConnectManifestRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateConnectManifestRequest',
    as HashRef[GenerateConnectManifestRequest()];

declare 'GenerateConnectManifestResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GenerateConnectManifestResponse'];

coerce 'GenerateConnectManifestResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GenerateConnectManifestResponse'->new($_) };

declare 'RepeatedGenerateConnectManifestResponse',
    as ArrayRef[GenerateConnectManifestResponse()];

coerce 'RepeatedGenerateConnectManifestResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GenerateConnectManifestResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateConnectManifestResponse',
    as HashRef[GenerateConnectManifestResponse()];

declare 'ConnectAgentResource',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ConnectAgentResource'];

coerce 'ConnectAgentResource',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ConnectAgentResource'->new($_) };

declare 'RepeatedConnectAgentResource',
    as ArrayRef[ConnectAgentResource()];

coerce 'RepeatedConnectAgentResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ConnectAgentResource'->new($_) } @$_ ] };

declare 'MapStringConnectAgentResource',
    as HashRef[ConnectAgentResource()];

declare 'TypeMeta',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::TypeMeta'];

coerce 'TypeMeta',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::TypeMeta'->new($_) };

declare 'RepeatedTypeMeta',
    as ArrayRef[TypeMeta()];

coerce 'RepeatedTypeMeta',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::TypeMeta'->new($_) } @$_ ] };

declare 'MapStringTypeMeta',
    as HashRef[TypeMeta()];

declare 'ListFeaturesRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListFeaturesRequest'];

coerce 'ListFeaturesRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListFeaturesRequest'->new($_) };

declare 'RepeatedListFeaturesRequest',
    as ArrayRef[ListFeaturesRequest()];

coerce 'RepeatedListFeaturesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListFeaturesRequest'->new($_) } @$_ ] };

declare 'MapStringListFeaturesRequest',
    as HashRef[ListFeaturesRequest()];

declare 'ListFeaturesResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListFeaturesResponse'];

coerce 'ListFeaturesResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListFeaturesResponse'->new($_) };

declare 'RepeatedListFeaturesResponse',
    as ArrayRef[ListFeaturesResponse()];

coerce 'RepeatedListFeaturesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListFeaturesResponse'->new($_) } @$_ ] };

declare 'MapStringListFeaturesResponse',
    as HashRef[ListFeaturesResponse()];

declare 'GetFeatureRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GetFeatureRequest'];

coerce 'GetFeatureRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GetFeatureRequest'->new($_) };

declare 'RepeatedGetFeatureRequest',
    as ArrayRef[GetFeatureRequest()];

coerce 'RepeatedGetFeatureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GetFeatureRequest'->new($_) } @$_ ] };

declare 'MapStringGetFeatureRequest',
    as HashRef[GetFeatureRequest()];

declare 'CreateFeatureRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::CreateFeatureRequest'];

coerce 'CreateFeatureRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::CreateFeatureRequest'->new($_) };

declare 'RepeatedCreateFeatureRequest',
    as ArrayRef[CreateFeatureRequest()];

coerce 'RepeatedCreateFeatureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::CreateFeatureRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFeatureRequest',
    as HashRef[CreateFeatureRequest()];

declare 'DeleteFeatureRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::DeleteFeatureRequest'];

coerce 'DeleteFeatureRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::DeleteFeatureRequest'->new($_) };

declare 'RepeatedDeleteFeatureRequest',
    as ArrayRef[DeleteFeatureRequest()];

coerce 'RepeatedDeleteFeatureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::DeleteFeatureRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFeatureRequest',
    as HashRef[DeleteFeatureRequest()];

declare 'UpdateFeatureRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::UpdateFeatureRequest'];

coerce 'UpdateFeatureRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::UpdateFeatureRequest'->new($_) };

declare 'RepeatedUpdateFeatureRequest',
    as ArrayRef[UpdateFeatureRequest()];

coerce 'RepeatedUpdateFeatureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::UpdateFeatureRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFeatureRequest',
    as HashRef[UpdateFeatureRequest()];

declare 'CreateFleetRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::CreateFleetRequest'];

coerce 'CreateFleetRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::CreateFleetRequest'->new($_) };

declare 'RepeatedCreateFleetRequest',
    as ArrayRef[CreateFleetRequest()];

coerce 'RepeatedCreateFleetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::CreateFleetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFleetRequest',
    as HashRef[CreateFleetRequest()];

declare 'GetFleetRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::GetFleetRequest'];

coerce 'GetFleetRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::GetFleetRequest'->new($_) };

declare 'RepeatedGetFleetRequest',
    as ArrayRef[GetFleetRequest()];

coerce 'RepeatedGetFleetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::GetFleetRequest'->new($_) } @$_ ] };

declare 'MapStringGetFleetRequest',
    as HashRef[GetFleetRequest()];

declare 'UpdateFleetRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::UpdateFleetRequest'];

coerce 'UpdateFleetRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::UpdateFleetRequest'->new($_) };

declare 'RepeatedUpdateFleetRequest',
    as ArrayRef[UpdateFleetRequest()];

coerce 'RepeatedUpdateFleetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::UpdateFleetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFleetRequest',
    as HashRef[UpdateFleetRequest()];

declare 'DeleteFleetRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::DeleteFleetRequest'];

coerce 'DeleteFleetRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::DeleteFleetRequest'->new($_) };

declare 'RepeatedDeleteFleetRequest',
    as ArrayRef[DeleteFleetRequest()];

coerce 'RepeatedDeleteFleetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::DeleteFleetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFleetRequest',
    as HashRef[DeleteFleetRequest()];

declare 'ListFleetsRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListFleetsRequest'];

coerce 'ListFleetsRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListFleetsRequest'->new($_) };

declare 'RepeatedListFleetsRequest',
    as ArrayRef[ListFleetsRequest()];

coerce 'RepeatedListFleetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListFleetsRequest'->new($_) } @$_ ] };

declare 'MapStringListFleetsRequest',
    as HashRef[ListFleetsRequest()];

declare 'ListFleetsResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::ListFleetsResponse'];

coerce 'ListFleetsResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::ListFleetsResponse'->new($_) };

declare 'RepeatedListFleetsResponse',
    as ArrayRef[ListFleetsResponse()];

coerce 'RepeatedListFleetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::ListFleetsResponse'->new($_) } @$_ ] };

declare 'MapStringListFleetsResponse',
    as HashRef[ListFleetsResponse()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Gkehub::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
