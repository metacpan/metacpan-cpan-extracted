package Google::Iam::V1beta::WorkloadIdentityPool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WorkloadIdentityPool',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPool'];

coerce 'WorkloadIdentityPool',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPool'->new($_) };

declare 'RepeatedWorkloadIdentityPool',
    as ArrayRef[WorkloadIdentityPool()];

coerce 'RepeatedWorkloadIdentityPool',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPool'->new($_) } @$_ ] };

declare 'MapStringWorkloadIdentityPool',
    as HashRef[WorkloadIdentityPool()];

declare 'State',
    as (Int | Str);

declare 'WorkloadIdentityPoolProvider',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider'];

coerce 'WorkloadIdentityPoolProvider',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider'->new($_) };

declare 'RepeatedWorkloadIdentityPoolProvider',
    as ArrayRef[WorkloadIdentityPoolProvider()];

coerce 'RepeatedWorkloadIdentityPoolProvider',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider'->new($_) } @$_ ] };

declare 'MapStringWorkloadIdentityPoolProvider',
    as HashRef[WorkloadIdentityPoolProvider()];

declare 'State',
    as (Int | Str);

declare 'Aws',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider::Aws'];

coerce 'Aws',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider::Aws'->new($_) };

declare 'RepeatedAws',
    as ArrayRef[Aws()];

coerce 'RepeatedAws',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider::Aws'->new($_) } @$_ ] };

declare 'MapStringAws',
    as HashRef[Aws()];

declare 'Oidc',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider::Oidc'];

coerce 'Oidc',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider::Oidc'->new($_) };

declare 'RepeatedOidc',
    as ArrayRef[Oidc()];

coerce 'RepeatedOidc',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider::Oidc'->new($_) } @$_ ] };

declare 'MapStringOidc',
    as HashRef[Oidc()];

declare 'AttributeMappingEntry',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider::AttributeMappingEntry'];

coerce 'AttributeMappingEntry',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider::AttributeMappingEntry'->new($_) };

declare 'RepeatedAttributeMappingEntry',
    as ArrayRef[AttributeMappingEntry()];

coerce 'RepeatedAttributeMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProvider::AttributeMappingEntry'->new($_) } @$_ ] };

declare 'MapStringAttributeMappingEntry',
    as HashRef[AttributeMappingEntry()];

declare 'ListWorkloadIdentityPoolsRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolsRequest'];

coerce 'ListWorkloadIdentityPoolsRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolsRequest'->new($_) };

declare 'RepeatedListWorkloadIdentityPoolsRequest',
    as ArrayRef[ListWorkloadIdentityPoolsRequest()];

coerce 'RepeatedListWorkloadIdentityPoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkloadIdentityPoolsRequest',
    as HashRef[ListWorkloadIdentityPoolsRequest()];

declare 'ListWorkloadIdentityPoolsResponse',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolsResponse'];

coerce 'ListWorkloadIdentityPoolsResponse',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolsResponse'->new($_) };

declare 'RepeatedListWorkloadIdentityPoolsResponse',
    as ArrayRef[ListWorkloadIdentityPoolsResponse()];

coerce 'RepeatedListWorkloadIdentityPoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkloadIdentityPoolsResponse',
    as HashRef[ListWorkloadIdentityPoolsResponse()];

declare 'GetWorkloadIdentityPoolRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::GetWorkloadIdentityPoolRequest'];

coerce 'GetWorkloadIdentityPoolRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::GetWorkloadIdentityPoolRequest'->new($_) };

declare 'RepeatedGetWorkloadIdentityPoolRequest',
    as ArrayRef[GetWorkloadIdentityPoolRequest()];

coerce 'RepeatedGetWorkloadIdentityPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::GetWorkloadIdentityPoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkloadIdentityPoolRequest',
    as HashRef[GetWorkloadIdentityPoolRequest()];

declare 'CreateWorkloadIdentityPoolRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::CreateWorkloadIdentityPoolRequest'];

coerce 'CreateWorkloadIdentityPoolRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::CreateWorkloadIdentityPoolRequest'->new($_) };

declare 'RepeatedCreateWorkloadIdentityPoolRequest',
    as ArrayRef[CreateWorkloadIdentityPoolRequest()];

coerce 'RepeatedCreateWorkloadIdentityPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::CreateWorkloadIdentityPoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkloadIdentityPoolRequest',
    as HashRef[CreateWorkloadIdentityPoolRequest()];

declare 'UpdateWorkloadIdentityPoolRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::UpdateWorkloadIdentityPoolRequest'];

coerce 'UpdateWorkloadIdentityPoolRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::UpdateWorkloadIdentityPoolRequest'->new($_) };

declare 'RepeatedUpdateWorkloadIdentityPoolRequest',
    as ArrayRef[UpdateWorkloadIdentityPoolRequest()];

coerce 'RepeatedUpdateWorkloadIdentityPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::UpdateWorkloadIdentityPoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkloadIdentityPoolRequest',
    as HashRef[UpdateWorkloadIdentityPoolRequest()];

declare 'DeleteWorkloadIdentityPoolRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::DeleteWorkloadIdentityPoolRequest'];

coerce 'DeleteWorkloadIdentityPoolRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::DeleteWorkloadIdentityPoolRequest'->new($_) };

declare 'RepeatedDeleteWorkloadIdentityPoolRequest',
    as ArrayRef[DeleteWorkloadIdentityPoolRequest()];

coerce 'RepeatedDeleteWorkloadIdentityPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::DeleteWorkloadIdentityPoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkloadIdentityPoolRequest',
    as HashRef[DeleteWorkloadIdentityPoolRequest()];

declare 'UndeleteWorkloadIdentityPoolRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::UndeleteWorkloadIdentityPoolRequest'];

coerce 'UndeleteWorkloadIdentityPoolRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::UndeleteWorkloadIdentityPoolRequest'->new($_) };

declare 'RepeatedUndeleteWorkloadIdentityPoolRequest',
    as ArrayRef[UndeleteWorkloadIdentityPoolRequest()];

coerce 'RepeatedUndeleteWorkloadIdentityPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::UndeleteWorkloadIdentityPoolRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteWorkloadIdentityPoolRequest',
    as HashRef[UndeleteWorkloadIdentityPoolRequest()];

declare 'ListWorkloadIdentityPoolProvidersRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolProvidersRequest'];

coerce 'ListWorkloadIdentityPoolProvidersRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolProvidersRequest'->new($_) };

declare 'RepeatedListWorkloadIdentityPoolProvidersRequest',
    as ArrayRef[ListWorkloadIdentityPoolProvidersRequest()];

coerce 'RepeatedListWorkloadIdentityPoolProvidersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolProvidersRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkloadIdentityPoolProvidersRequest',
    as HashRef[ListWorkloadIdentityPoolProvidersRequest()];

declare 'ListWorkloadIdentityPoolProvidersResponse',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolProvidersResponse'];

coerce 'ListWorkloadIdentityPoolProvidersResponse',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolProvidersResponse'->new($_) };

declare 'RepeatedListWorkloadIdentityPoolProvidersResponse',
    as ArrayRef[ListWorkloadIdentityPoolProvidersResponse()];

coerce 'RepeatedListWorkloadIdentityPoolProvidersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::ListWorkloadIdentityPoolProvidersResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkloadIdentityPoolProvidersResponse',
    as HashRef[ListWorkloadIdentityPoolProvidersResponse()];

declare 'GetWorkloadIdentityPoolProviderRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::GetWorkloadIdentityPoolProviderRequest'];

coerce 'GetWorkloadIdentityPoolProviderRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::GetWorkloadIdentityPoolProviderRequest'->new($_) };

declare 'RepeatedGetWorkloadIdentityPoolProviderRequest',
    as ArrayRef[GetWorkloadIdentityPoolProviderRequest()];

coerce 'RepeatedGetWorkloadIdentityPoolProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::GetWorkloadIdentityPoolProviderRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkloadIdentityPoolProviderRequest',
    as HashRef[GetWorkloadIdentityPoolProviderRequest()];

declare 'CreateWorkloadIdentityPoolProviderRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::CreateWorkloadIdentityPoolProviderRequest'];

coerce 'CreateWorkloadIdentityPoolProviderRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::CreateWorkloadIdentityPoolProviderRequest'->new($_) };

declare 'RepeatedCreateWorkloadIdentityPoolProviderRequest',
    as ArrayRef[CreateWorkloadIdentityPoolProviderRequest()];

coerce 'RepeatedCreateWorkloadIdentityPoolProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::CreateWorkloadIdentityPoolProviderRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkloadIdentityPoolProviderRequest',
    as HashRef[CreateWorkloadIdentityPoolProviderRequest()];

declare 'UpdateWorkloadIdentityPoolProviderRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::UpdateWorkloadIdentityPoolProviderRequest'];

coerce 'UpdateWorkloadIdentityPoolProviderRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::UpdateWorkloadIdentityPoolProviderRequest'->new($_) };

declare 'RepeatedUpdateWorkloadIdentityPoolProviderRequest',
    as ArrayRef[UpdateWorkloadIdentityPoolProviderRequest()];

coerce 'RepeatedUpdateWorkloadIdentityPoolProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::UpdateWorkloadIdentityPoolProviderRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkloadIdentityPoolProviderRequest',
    as HashRef[UpdateWorkloadIdentityPoolProviderRequest()];

declare 'DeleteWorkloadIdentityPoolProviderRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::DeleteWorkloadIdentityPoolProviderRequest'];

coerce 'DeleteWorkloadIdentityPoolProviderRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::DeleteWorkloadIdentityPoolProviderRequest'->new($_) };

declare 'RepeatedDeleteWorkloadIdentityPoolProviderRequest',
    as ArrayRef[DeleteWorkloadIdentityPoolProviderRequest()];

coerce 'RepeatedDeleteWorkloadIdentityPoolProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::DeleteWorkloadIdentityPoolProviderRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkloadIdentityPoolProviderRequest',
    as HashRef[DeleteWorkloadIdentityPoolProviderRequest()];

declare 'UndeleteWorkloadIdentityPoolProviderRequest',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::UndeleteWorkloadIdentityPoolProviderRequest'];

coerce 'UndeleteWorkloadIdentityPoolProviderRequest',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::UndeleteWorkloadIdentityPoolProviderRequest'->new($_) };

declare 'RepeatedUndeleteWorkloadIdentityPoolProviderRequest',
    as ArrayRef[UndeleteWorkloadIdentityPoolProviderRequest()];

coerce 'RepeatedUndeleteWorkloadIdentityPoolProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::UndeleteWorkloadIdentityPoolProviderRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteWorkloadIdentityPoolProviderRequest',
    as HashRef[UndeleteWorkloadIdentityPoolProviderRequest()];

declare 'WorkloadIdentityPoolOperationMetadata',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolOperationMetadata'];

coerce 'WorkloadIdentityPoolOperationMetadata',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolOperationMetadata'->new($_) };

declare 'RepeatedWorkloadIdentityPoolOperationMetadata',
    as ArrayRef[WorkloadIdentityPoolOperationMetadata()];

coerce 'RepeatedWorkloadIdentityPoolOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringWorkloadIdentityPoolOperationMetadata',
    as HashRef[WorkloadIdentityPoolOperationMetadata()];

declare 'WorkloadIdentityPoolProviderOperationMetadata',
    as InstanceOf['Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProviderOperationMetadata'];

coerce 'WorkloadIdentityPoolProviderOperationMetadata',
    from HashRef, via { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProviderOperationMetadata'->new($_) };

declare 'RepeatedWorkloadIdentityPoolProviderOperationMetadata',
    as ArrayRef[WorkloadIdentityPoolProviderOperationMetadata()];

coerce 'RepeatedWorkloadIdentityPoolProviderOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1beta::WorkloadIdentityPool::WorkloadIdentityPoolProviderOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringWorkloadIdentityPoolProviderOperationMetadata',
    as HashRef[WorkloadIdentityPoolProviderOperationMetadata()];

1;

__END__

=head1 NAME

Google::Iam::V1beta::WorkloadIdentityPool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
