package Google::Cloud::Gkemulticloud::V1::AzureService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateAzureClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureClusterRequest'];

coerce 'CreateAzureClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureClusterRequest'->new($_) };

declare 'RepeatedCreateAzureClusterRequest',
    as ArrayRef[CreateAzureClusterRequest()];

coerce 'RepeatedCreateAzureClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAzureClusterRequest',
    as HashRef[CreateAzureClusterRequest()];

declare 'UpdateAzureClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::UpdateAzureClusterRequest'];

coerce 'UpdateAzureClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::UpdateAzureClusterRequest'->new($_) };

declare 'RepeatedUpdateAzureClusterRequest',
    as ArrayRef[UpdateAzureClusterRequest()];

coerce 'RepeatedUpdateAzureClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::UpdateAzureClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAzureClusterRequest',
    as HashRef[UpdateAzureClusterRequest()];

declare 'GetAzureClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureClusterRequest'];

coerce 'GetAzureClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureClusterRequest'->new($_) };

declare 'RepeatedGetAzureClusterRequest',
    as ArrayRef[GetAzureClusterRequest()];

coerce 'RepeatedGetAzureClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetAzureClusterRequest',
    as HashRef[GetAzureClusterRequest()];

declare 'ListAzureClustersRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClustersRequest'];

coerce 'ListAzureClustersRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClustersRequest'->new($_) };

declare 'RepeatedListAzureClustersRequest',
    as ArrayRef[ListAzureClustersRequest()];

coerce 'RepeatedListAzureClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListAzureClustersRequest',
    as HashRef[ListAzureClustersRequest()];

declare 'ListAzureClustersResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClustersResponse'];

coerce 'ListAzureClustersResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClustersResponse'->new($_) };

declare 'RepeatedListAzureClustersResponse',
    as ArrayRef[ListAzureClustersResponse()];

coerce 'RepeatedListAzureClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListAzureClustersResponse',
    as HashRef[ListAzureClustersResponse()];

declare 'DeleteAzureClusterRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::DeleteAzureClusterRequest'];

coerce 'DeleteAzureClusterRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::DeleteAzureClusterRequest'->new($_) };

declare 'RepeatedDeleteAzureClusterRequest',
    as ArrayRef[DeleteAzureClusterRequest()];

coerce 'RepeatedDeleteAzureClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::DeleteAzureClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAzureClusterRequest',
    as HashRef[DeleteAzureClusterRequest()];

declare 'CreateAzureNodePoolRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureNodePoolRequest'];

coerce 'CreateAzureNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureNodePoolRequest'->new($_) };

declare 'RepeatedCreateAzureNodePoolRequest',
    as ArrayRef[CreateAzureNodePoolRequest()];

coerce 'RepeatedCreateAzureNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAzureNodePoolRequest',
    as HashRef[CreateAzureNodePoolRequest()];

declare 'UpdateAzureNodePoolRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::UpdateAzureNodePoolRequest'];

coerce 'UpdateAzureNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::UpdateAzureNodePoolRequest'->new($_) };

declare 'RepeatedUpdateAzureNodePoolRequest',
    as ArrayRef[UpdateAzureNodePoolRequest()];

coerce 'RepeatedUpdateAzureNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::UpdateAzureNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAzureNodePoolRequest',
    as HashRef[UpdateAzureNodePoolRequest()];

declare 'GetAzureNodePoolRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureNodePoolRequest'];

coerce 'GetAzureNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureNodePoolRequest'->new($_) };

declare 'RepeatedGetAzureNodePoolRequest',
    as ArrayRef[GetAzureNodePoolRequest()];

coerce 'RepeatedGetAzureNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetAzureNodePoolRequest',
    as HashRef[GetAzureNodePoolRequest()];

declare 'ListAzureNodePoolsRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureNodePoolsRequest'];

coerce 'ListAzureNodePoolsRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureNodePoolsRequest'->new($_) };

declare 'RepeatedListAzureNodePoolsRequest',
    as ArrayRef[ListAzureNodePoolsRequest()];

coerce 'RepeatedListAzureNodePoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureNodePoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListAzureNodePoolsRequest',
    as HashRef[ListAzureNodePoolsRequest()];

declare 'ListAzureNodePoolsResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureNodePoolsResponse'];

coerce 'ListAzureNodePoolsResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureNodePoolsResponse'->new($_) };

declare 'RepeatedListAzureNodePoolsResponse',
    as ArrayRef[ListAzureNodePoolsResponse()];

coerce 'RepeatedListAzureNodePoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureNodePoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListAzureNodePoolsResponse',
    as HashRef[ListAzureNodePoolsResponse()];

declare 'DeleteAzureNodePoolRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::DeleteAzureNodePoolRequest'];

coerce 'DeleteAzureNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::DeleteAzureNodePoolRequest'->new($_) };

declare 'RepeatedDeleteAzureNodePoolRequest',
    as ArrayRef[DeleteAzureNodePoolRequest()];

coerce 'RepeatedDeleteAzureNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::DeleteAzureNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAzureNodePoolRequest',
    as HashRef[DeleteAzureNodePoolRequest()];

declare 'GetAzureOpenIdConfigRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureOpenIdConfigRequest'];

coerce 'GetAzureOpenIdConfigRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureOpenIdConfigRequest'->new($_) };

declare 'RepeatedGetAzureOpenIdConfigRequest',
    as ArrayRef[GetAzureOpenIdConfigRequest()];

coerce 'RepeatedGetAzureOpenIdConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureOpenIdConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAzureOpenIdConfigRequest',
    as HashRef[GetAzureOpenIdConfigRequest()];

declare 'GetAzureJsonWebKeysRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureJsonWebKeysRequest'];

coerce 'GetAzureJsonWebKeysRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureJsonWebKeysRequest'->new($_) };

declare 'RepeatedGetAzureJsonWebKeysRequest',
    as ArrayRef[GetAzureJsonWebKeysRequest()];

coerce 'RepeatedGetAzureJsonWebKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureJsonWebKeysRequest'->new($_) } @$_ ] };

declare 'MapStringGetAzureJsonWebKeysRequest',
    as HashRef[GetAzureJsonWebKeysRequest()];

declare 'GetAzureServerConfigRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureServerConfigRequest'];

coerce 'GetAzureServerConfigRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureServerConfigRequest'->new($_) };

declare 'RepeatedGetAzureServerConfigRequest',
    as ArrayRef[GetAzureServerConfigRequest()];

coerce 'RepeatedGetAzureServerConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureServerConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAzureServerConfigRequest',
    as HashRef[GetAzureServerConfigRequest()];

declare 'CreateAzureClientRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureClientRequest'];

coerce 'CreateAzureClientRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureClientRequest'->new($_) };

declare 'RepeatedCreateAzureClientRequest',
    as ArrayRef[CreateAzureClientRequest()];

coerce 'RepeatedCreateAzureClientRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureClientRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAzureClientRequest',
    as HashRef[CreateAzureClientRequest()];

declare 'GetAzureClientRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureClientRequest'];

coerce 'GetAzureClientRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureClientRequest'->new($_) };

declare 'RepeatedGetAzureClientRequest',
    as ArrayRef[GetAzureClientRequest()];

coerce 'RepeatedGetAzureClientRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::GetAzureClientRequest'->new($_) } @$_ ] };

declare 'MapStringGetAzureClientRequest',
    as HashRef[GetAzureClientRequest()];

declare 'ListAzureClientsRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClientsRequest'];

coerce 'ListAzureClientsRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClientsRequest'->new($_) };

declare 'RepeatedListAzureClientsRequest',
    as ArrayRef[ListAzureClientsRequest()];

coerce 'RepeatedListAzureClientsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClientsRequest'->new($_) } @$_ ] };

declare 'MapStringListAzureClientsRequest',
    as HashRef[ListAzureClientsRequest()];

declare 'ListAzureClientsResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClientsResponse'];

coerce 'ListAzureClientsResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClientsResponse'->new($_) };

declare 'RepeatedListAzureClientsResponse',
    as ArrayRef[ListAzureClientsResponse()];

coerce 'RepeatedListAzureClientsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::ListAzureClientsResponse'->new($_) } @$_ ] };

declare 'MapStringListAzureClientsResponse',
    as HashRef[ListAzureClientsResponse()];

declare 'DeleteAzureClientRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::DeleteAzureClientRequest'];

coerce 'DeleteAzureClientRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::DeleteAzureClientRequest'->new($_) };

declare 'RepeatedDeleteAzureClientRequest',
    as ArrayRef[DeleteAzureClientRequest()];

coerce 'RepeatedDeleteAzureClientRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::DeleteAzureClientRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAzureClientRequest',
    as HashRef[DeleteAzureClientRequest()];

declare 'GenerateAzureAccessTokenRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureAccessTokenRequest'];

coerce 'GenerateAzureAccessTokenRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureAccessTokenRequest'->new($_) };

declare 'RepeatedGenerateAzureAccessTokenRequest',
    as ArrayRef[GenerateAzureAccessTokenRequest()];

coerce 'RepeatedGenerateAzureAccessTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureAccessTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAzureAccessTokenRequest',
    as HashRef[GenerateAzureAccessTokenRequest()];

declare 'GenerateAzureAccessTokenResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureAccessTokenResponse'];

coerce 'GenerateAzureAccessTokenResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureAccessTokenResponse'->new($_) };

declare 'RepeatedGenerateAzureAccessTokenResponse',
    as ArrayRef[GenerateAzureAccessTokenResponse()];

coerce 'RepeatedGenerateAzureAccessTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureAccessTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAzureAccessTokenResponse',
    as HashRef[GenerateAzureAccessTokenResponse()];

declare 'GenerateAzureClusterAgentTokenRequest',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureClusterAgentTokenRequest'];

coerce 'GenerateAzureClusterAgentTokenRequest',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureClusterAgentTokenRequest'->new($_) };

declare 'RepeatedGenerateAzureClusterAgentTokenRequest',
    as ArrayRef[GenerateAzureClusterAgentTokenRequest()];

coerce 'RepeatedGenerateAzureClusterAgentTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureClusterAgentTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAzureClusterAgentTokenRequest',
    as HashRef[GenerateAzureClusterAgentTokenRequest()];

declare 'GenerateAzureClusterAgentTokenResponse',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureClusterAgentTokenResponse'];

coerce 'GenerateAzureClusterAgentTokenResponse',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureClusterAgentTokenResponse'->new($_) };

declare 'RepeatedGenerateAzureClusterAgentTokenResponse',
    as ArrayRef[GenerateAzureClusterAgentTokenResponse()];

coerce 'RepeatedGenerateAzureClusterAgentTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureService::GenerateAzureClusterAgentTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAzureClusterAgentTokenResponse',
    as HashRef[GenerateAzureClusterAgentTokenResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Gkemulticloud::V1::AzureService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
