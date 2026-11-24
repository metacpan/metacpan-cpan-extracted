package Google::Cloud::Gkemulticloud::V1::AwsService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateAwsClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::CreateAwsClusterRequest'];

coerce 'CreateAwsClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::CreateAwsClusterRequest'->new($_) };

declare 'RepeatedCreateAwsClusterRequest',
    as ArrayRef[CreateAwsClusterRequest()];

coerce 'RepeatedCreateAwsClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::CreateAwsClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAwsClusterRequest',
    as HashRef[CreateAwsClusterRequest()];

declare 'UpdateAwsClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::UpdateAwsClusterRequest'];

coerce 'UpdateAwsClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::UpdateAwsClusterRequest'->new($_) };

declare 'RepeatedUpdateAwsClusterRequest',
    as ArrayRef[UpdateAwsClusterRequest()];

coerce 'RepeatedUpdateAwsClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::UpdateAwsClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAwsClusterRequest',
    as HashRef[UpdateAwsClusterRequest()];

declare 'GetAwsClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsClusterRequest'];

coerce 'GetAwsClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsClusterRequest'->new($_) };

declare 'RepeatedGetAwsClusterRequest',
    as ArrayRef[GetAwsClusterRequest()];

coerce 'RepeatedGetAwsClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetAwsClusterRequest',
    as HashRef[GetAwsClusterRequest()];

declare 'ListAwsClustersRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsClustersRequest'];

coerce 'ListAwsClustersRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsClustersRequest'->new($_) };

declare 'RepeatedListAwsClustersRequest',
    as ArrayRef[ListAwsClustersRequest()];

coerce 'RepeatedListAwsClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListAwsClustersRequest',
    as HashRef[ListAwsClustersRequest()];

declare 'ListAwsClustersResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsClustersResponse'];

coerce 'ListAwsClustersResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsClustersResponse'->new($_) };

declare 'RepeatedListAwsClustersResponse',
    as ArrayRef[ListAwsClustersResponse()];

coerce 'RepeatedListAwsClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListAwsClustersResponse',
    as HashRef[ListAwsClustersResponse()];

declare 'DeleteAwsClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::DeleteAwsClusterRequest'];

coerce 'DeleteAwsClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::DeleteAwsClusterRequest'->new($_) };

declare 'RepeatedDeleteAwsClusterRequest',
    as ArrayRef[DeleteAwsClusterRequest()];

coerce 'RepeatedDeleteAwsClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::DeleteAwsClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAwsClusterRequest',
    as HashRef[DeleteAwsClusterRequest()];

declare 'CreateAwsNodePoolRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::CreateAwsNodePoolRequest'];

coerce 'CreateAwsNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::CreateAwsNodePoolRequest'->new($_) };

declare 'RepeatedCreateAwsNodePoolRequest',
    as ArrayRef[CreateAwsNodePoolRequest()];

coerce 'RepeatedCreateAwsNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::CreateAwsNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAwsNodePoolRequest',
    as HashRef[CreateAwsNodePoolRequest()];

declare 'UpdateAwsNodePoolRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::UpdateAwsNodePoolRequest'];

coerce 'UpdateAwsNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::UpdateAwsNodePoolRequest'->new($_) };

declare 'RepeatedUpdateAwsNodePoolRequest',
    as ArrayRef[UpdateAwsNodePoolRequest()];

coerce 'RepeatedUpdateAwsNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::UpdateAwsNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAwsNodePoolRequest',
    as HashRef[UpdateAwsNodePoolRequest()];

declare 'RollbackAwsNodePoolUpdateRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::RollbackAwsNodePoolUpdateRequest'];

coerce 'RollbackAwsNodePoolUpdateRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::RollbackAwsNodePoolUpdateRequest'->new($_) };

declare 'RepeatedRollbackAwsNodePoolUpdateRequest',
    as ArrayRef[RollbackAwsNodePoolUpdateRequest()];

coerce 'RepeatedRollbackAwsNodePoolUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::RollbackAwsNodePoolUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackAwsNodePoolUpdateRequest',
    as HashRef[RollbackAwsNodePoolUpdateRequest()];

declare 'GetAwsNodePoolRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsNodePoolRequest'];

coerce 'GetAwsNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsNodePoolRequest'->new($_) };

declare 'RepeatedGetAwsNodePoolRequest',
    as ArrayRef[GetAwsNodePoolRequest()];

coerce 'RepeatedGetAwsNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetAwsNodePoolRequest',
    as HashRef[GetAwsNodePoolRequest()];

declare 'ListAwsNodePoolsRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsNodePoolsRequest'];

coerce 'ListAwsNodePoolsRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsNodePoolsRequest'->new($_) };

declare 'RepeatedListAwsNodePoolsRequest',
    as ArrayRef[ListAwsNodePoolsRequest()];

coerce 'RepeatedListAwsNodePoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsNodePoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListAwsNodePoolsRequest',
    as HashRef[ListAwsNodePoolsRequest()];

declare 'ListAwsNodePoolsResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsNodePoolsResponse'];

coerce 'ListAwsNodePoolsResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsNodePoolsResponse'->new($_) };

declare 'RepeatedListAwsNodePoolsResponse',
    as ArrayRef[ListAwsNodePoolsResponse()];

coerce 'RepeatedListAwsNodePoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::ListAwsNodePoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListAwsNodePoolsResponse',
    as HashRef[ListAwsNodePoolsResponse()];

declare 'DeleteAwsNodePoolRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::DeleteAwsNodePoolRequest'];

coerce 'DeleteAwsNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::DeleteAwsNodePoolRequest'->new($_) };

declare 'RepeatedDeleteAwsNodePoolRequest',
    as ArrayRef[DeleteAwsNodePoolRequest()];

coerce 'RepeatedDeleteAwsNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::DeleteAwsNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAwsNodePoolRequest',
    as HashRef[DeleteAwsNodePoolRequest()];

declare 'GetAwsOpenIdConfigRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsOpenIdConfigRequest'];

coerce 'GetAwsOpenIdConfigRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsOpenIdConfigRequest'->new($_) };

declare 'RepeatedGetAwsOpenIdConfigRequest',
    as ArrayRef[GetAwsOpenIdConfigRequest()];

coerce 'RepeatedGetAwsOpenIdConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsOpenIdConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAwsOpenIdConfigRequest',
    as HashRef[GetAwsOpenIdConfigRequest()];

declare 'GetAwsJsonWebKeysRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsJsonWebKeysRequest'];

coerce 'GetAwsJsonWebKeysRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsJsonWebKeysRequest'->new($_) };

declare 'RepeatedGetAwsJsonWebKeysRequest',
    as ArrayRef[GetAwsJsonWebKeysRequest()];

coerce 'RepeatedGetAwsJsonWebKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsJsonWebKeysRequest'->new($_) } @$_ ] };

declare 'MapStringGetAwsJsonWebKeysRequest',
    as HashRef[GetAwsJsonWebKeysRequest()];

declare 'GetAwsServerConfigRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsServerConfigRequest'];

coerce 'GetAwsServerConfigRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsServerConfigRequest'->new($_) };

declare 'RepeatedGetAwsServerConfigRequest',
    as ArrayRef[GetAwsServerConfigRequest()];

coerce 'RepeatedGetAwsServerConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::GetAwsServerConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAwsServerConfigRequest',
    as HashRef[GetAwsServerConfigRequest()];

declare 'GenerateAwsAccessTokenRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsAccessTokenRequest'];

coerce 'GenerateAwsAccessTokenRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsAccessTokenRequest'->new($_) };

declare 'RepeatedGenerateAwsAccessTokenRequest',
    as ArrayRef[GenerateAwsAccessTokenRequest()];

coerce 'RepeatedGenerateAwsAccessTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsAccessTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAwsAccessTokenRequest',
    as HashRef[GenerateAwsAccessTokenRequest()];

declare 'GenerateAwsAccessTokenResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsAccessTokenResponse'];

coerce 'GenerateAwsAccessTokenResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsAccessTokenResponse'->new($_) };

declare 'RepeatedGenerateAwsAccessTokenResponse',
    as ArrayRef[GenerateAwsAccessTokenResponse()];

coerce 'RepeatedGenerateAwsAccessTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsAccessTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAwsAccessTokenResponse',
    as HashRef[GenerateAwsAccessTokenResponse()];

declare 'GenerateAwsClusterAgentTokenRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsClusterAgentTokenRequest'];

coerce 'GenerateAwsClusterAgentTokenRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsClusterAgentTokenRequest'->new($_) };

declare 'RepeatedGenerateAwsClusterAgentTokenRequest',
    as ArrayRef[GenerateAwsClusterAgentTokenRequest()];

coerce 'RepeatedGenerateAwsClusterAgentTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsClusterAgentTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAwsClusterAgentTokenRequest',
    as HashRef[GenerateAwsClusterAgentTokenRequest()];

declare 'GenerateAwsClusterAgentTokenResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsClusterAgentTokenResponse'];

coerce 'GenerateAwsClusterAgentTokenResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsClusterAgentTokenResponse'->new($_) };

declare 'RepeatedGenerateAwsClusterAgentTokenResponse',
    as ArrayRef[GenerateAwsClusterAgentTokenResponse()];

coerce 'RepeatedGenerateAwsClusterAgentTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsService::GenerateAwsClusterAgentTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAwsClusterAgentTokenResponse',
    as HashRef[GenerateAwsClusterAgentTokenResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Gkemulticloud::V1::AwsService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
