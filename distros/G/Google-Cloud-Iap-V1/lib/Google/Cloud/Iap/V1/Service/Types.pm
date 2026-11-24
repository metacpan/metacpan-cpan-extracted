package Google::Cloud::Iap::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListTunnelDestGroupsRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsRequest'];

coerce 'ListTunnelDestGroupsRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsRequest'->new($_) };

declare 'RepeatedListTunnelDestGroupsRequest',
    as ArrayRef[ListTunnelDestGroupsRequest()];

coerce 'RepeatedListTunnelDestGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListTunnelDestGroupsRequest',
    as HashRef[ListTunnelDestGroupsRequest()];

declare 'ListTunnelDestGroupsResponse',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsResponse'];

coerce 'ListTunnelDestGroupsResponse',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsResponse'->new($_) };

declare 'RepeatedListTunnelDestGroupsResponse',
    as ArrayRef[ListTunnelDestGroupsResponse()];

coerce 'RepeatedListTunnelDestGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListTunnelDestGroupsResponse',
    as HashRef[ListTunnelDestGroupsResponse()];

declare 'CreateTunnelDestGroupRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::CreateTunnelDestGroupRequest'];

coerce 'CreateTunnelDestGroupRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::CreateTunnelDestGroupRequest'->new($_) };

declare 'RepeatedCreateTunnelDestGroupRequest',
    as ArrayRef[CreateTunnelDestGroupRequest()];

coerce 'RepeatedCreateTunnelDestGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::CreateTunnelDestGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTunnelDestGroupRequest',
    as HashRef[CreateTunnelDestGroupRequest()];

declare 'GetTunnelDestGroupRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::GetTunnelDestGroupRequest'];

coerce 'GetTunnelDestGroupRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::GetTunnelDestGroupRequest'->new($_) };

declare 'RepeatedGetTunnelDestGroupRequest',
    as ArrayRef[GetTunnelDestGroupRequest()];

coerce 'RepeatedGetTunnelDestGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::GetTunnelDestGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetTunnelDestGroupRequest',
    as HashRef[GetTunnelDestGroupRequest()];

declare 'DeleteTunnelDestGroupRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::DeleteTunnelDestGroupRequest'];

coerce 'DeleteTunnelDestGroupRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::DeleteTunnelDestGroupRequest'->new($_) };

declare 'RepeatedDeleteTunnelDestGroupRequest',
    as ArrayRef[DeleteTunnelDestGroupRequest()];

coerce 'RepeatedDeleteTunnelDestGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::DeleteTunnelDestGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTunnelDestGroupRequest',
    as HashRef[DeleteTunnelDestGroupRequest()];

declare 'UpdateTunnelDestGroupRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::UpdateTunnelDestGroupRequest'];

coerce 'UpdateTunnelDestGroupRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::UpdateTunnelDestGroupRequest'->new($_) };

declare 'RepeatedUpdateTunnelDestGroupRequest',
    as ArrayRef[UpdateTunnelDestGroupRequest()];

coerce 'RepeatedUpdateTunnelDestGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::UpdateTunnelDestGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTunnelDestGroupRequest',
    as HashRef[UpdateTunnelDestGroupRequest()];

declare 'TunnelDestGroup',
    as InstanceOf['Google::Cloud::Iap::V1::Service::TunnelDestGroup'];

coerce 'TunnelDestGroup',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::TunnelDestGroup'->new($_) };

declare 'RepeatedTunnelDestGroup',
    as ArrayRef[TunnelDestGroup()];

coerce 'RepeatedTunnelDestGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::TunnelDestGroup'->new($_) } @$_ ] };

declare 'MapStringTunnelDestGroup',
    as HashRef[TunnelDestGroup()];

declare 'GetIapSettingsRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::GetIapSettingsRequest'];

coerce 'GetIapSettingsRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::GetIapSettingsRequest'->new($_) };

declare 'RepeatedGetIapSettingsRequest',
    as ArrayRef[GetIapSettingsRequest()];

coerce 'RepeatedGetIapSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::GetIapSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetIapSettingsRequest',
    as HashRef[GetIapSettingsRequest()];

declare 'UpdateIapSettingsRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::UpdateIapSettingsRequest'];

coerce 'UpdateIapSettingsRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::UpdateIapSettingsRequest'->new($_) };

declare 'RepeatedUpdateIapSettingsRequest',
    as ArrayRef[UpdateIapSettingsRequest()];

coerce 'RepeatedUpdateIapSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::UpdateIapSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIapSettingsRequest',
    as HashRef[UpdateIapSettingsRequest()];

declare 'IapSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::IapSettings'];

coerce 'IapSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::IapSettings'->new($_) };

declare 'RepeatedIapSettings',
    as ArrayRef[IapSettings()];

coerce 'RepeatedIapSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::IapSettings'->new($_) } @$_ ] };

declare 'MapStringIapSettings',
    as HashRef[IapSettings()];

declare 'AccessSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::AccessSettings'];

coerce 'AccessSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::AccessSettings'->new($_) };

declare 'RepeatedAccessSettings',
    as ArrayRef[AccessSettings()];

coerce 'RepeatedAccessSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::AccessSettings'->new($_) } @$_ ] };

declare 'MapStringAccessSettings',
    as HashRef[AccessSettings()];

declare 'IdentitySource',
    as (Int | Str);

declare 'GcipSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::GcipSettings'];

coerce 'GcipSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::GcipSettings'->new($_) };

declare 'RepeatedGcipSettings',
    as ArrayRef[GcipSettings()];

coerce 'RepeatedGcipSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::GcipSettings'->new($_) } @$_ ] };

declare 'MapStringGcipSettings',
    as HashRef[GcipSettings()];

declare 'CorsSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::CorsSettings'];

coerce 'CorsSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::CorsSettings'->new($_) };

declare 'RepeatedCorsSettings',
    as ArrayRef[CorsSettings()];

coerce 'RepeatedCorsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::CorsSettings'->new($_) } @$_ ] };

declare 'MapStringCorsSettings',
    as HashRef[CorsSettings()];

declare 'OAuthSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::OAuthSettings'];

coerce 'OAuthSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::OAuthSettings'->new($_) };

declare 'RepeatedOAuthSettings',
    as ArrayRef[OAuthSettings()];

coerce 'RepeatedOAuthSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::OAuthSettings'->new($_) } @$_ ] };

declare 'MapStringOAuthSettings',
    as HashRef[OAuthSettings()];

declare 'WorkforceIdentitySettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::WorkforceIdentitySettings'];

coerce 'WorkforceIdentitySettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::WorkforceIdentitySettings'->new($_) };

declare 'RepeatedWorkforceIdentitySettings',
    as ArrayRef[WorkforceIdentitySettings()];

coerce 'RepeatedWorkforceIdentitySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::WorkforceIdentitySettings'->new($_) } @$_ ] };

declare 'MapStringWorkforceIdentitySettings',
    as HashRef[WorkforceIdentitySettings()];

declare 'OAuth2',
    as InstanceOf['Google::Cloud::Iap::V1::Service::OAuth2'];

coerce 'OAuth2',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::OAuth2'->new($_) };

declare 'RepeatedOAuth2',
    as ArrayRef[OAuth2()];

coerce 'RepeatedOAuth2',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::OAuth2'->new($_) } @$_ ] };

declare 'MapStringOAuth2',
    as HashRef[OAuth2()];

declare 'ReauthSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ReauthSettings'];

coerce 'ReauthSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ReauthSettings'->new($_) };

declare 'RepeatedReauthSettings',
    as ArrayRef[ReauthSettings()];

coerce 'RepeatedReauthSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ReauthSettings'->new($_) } @$_ ] };

declare 'MapStringReauthSettings',
    as HashRef[ReauthSettings()];

declare 'Method',
    as (Int | Str);

declare 'PolicyType',
    as (Int | Str);

declare 'AllowedDomainsSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::AllowedDomainsSettings'];

coerce 'AllowedDomainsSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::AllowedDomainsSettings'->new($_) };

declare 'RepeatedAllowedDomainsSettings',
    as ArrayRef[AllowedDomainsSettings()];

coerce 'RepeatedAllowedDomainsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::AllowedDomainsSettings'->new($_) } @$_ ] };

declare 'MapStringAllowedDomainsSettings',
    as HashRef[AllowedDomainsSettings()];

declare 'ApplicationSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ApplicationSettings'];

coerce 'ApplicationSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ApplicationSettings'->new($_) };

declare 'RepeatedApplicationSettings',
    as ArrayRef[ApplicationSettings()];

coerce 'RepeatedApplicationSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ApplicationSettings'->new($_) } @$_ ] };

declare 'MapStringApplicationSettings',
    as HashRef[ApplicationSettings()];

declare 'CsmSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::CsmSettings'];

coerce 'CsmSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::CsmSettings'->new($_) };

declare 'RepeatedCsmSettings',
    as ArrayRef[CsmSettings()];

coerce 'RepeatedCsmSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::CsmSettings'->new($_) } @$_ ] };

declare 'MapStringCsmSettings',
    as HashRef[CsmSettings()];

declare 'AccessDeniedPageSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::AccessDeniedPageSettings'];

coerce 'AccessDeniedPageSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::AccessDeniedPageSettings'->new($_) };

declare 'RepeatedAccessDeniedPageSettings',
    as ArrayRef[AccessDeniedPageSettings()];

coerce 'RepeatedAccessDeniedPageSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::AccessDeniedPageSettings'->new($_) } @$_ ] };

declare 'MapStringAccessDeniedPageSettings',
    as HashRef[AccessDeniedPageSettings()];

declare 'AttributePropagationSettings',
    as InstanceOf['Google::Cloud::Iap::V1::Service::AttributePropagationSettings'];

coerce 'AttributePropagationSettings',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::AttributePropagationSettings'->new($_) };

declare 'RepeatedAttributePropagationSettings',
    as ArrayRef[AttributePropagationSettings()];

coerce 'RepeatedAttributePropagationSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::AttributePropagationSettings'->new($_) } @$_ ] };

declare 'MapStringAttributePropagationSettings',
    as HashRef[AttributePropagationSettings()];

declare 'OutputCredentials',
    as (Int | Str);

declare 'ValidateIapAttributeExpressionRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionRequest'];

coerce 'ValidateIapAttributeExpressionRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionRequest'->new($_) };

declare 'RepeatedValidateIapAttributeExpressionRequest',
    as ArrayRef[ValidateIapAttributeExpressionRequest()];

coerce 'RepeatedValidateIapAttributeExpressionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionRequest'->new($_) } @$_ ] };

declare 'MapStringValidateIapAttributeExpressionRequest',
    as HashRef[ValidateIapAttributeExpressionRequest()];

declare 'ValidateIapAttributeExpressionResponse',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionResponse'];

coerce 'ValidateIapAttributeExpressionResponse',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionResponse'->new($_) };

declare 'RepeatedValidateIapAttributeExpressionResponse',
    as ArrayRef[ValidateIapAttributeExpressionResponse()];

coerce 'RepeatedValidateIapAttributeExpressionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionResponse'->new($_) } @$_ ] };

declare 'MapStringValidateIapAttributeExpressionResponse',
    as HashRef[ValidateIapAttributeExpressionResponse()];

declare 'ListBrandsRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ListBrandsRequest'];

coerce 'ListBrandsRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ListBrandsRequest'->new($_) };

declare 'RepeatedListBrandsRequest',
    as ArrayRef[ListBrandsRequest()];

coerce 'RepeatedListBrandsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ListBrandsRequest'->new($_) } @$_ ] };

declare 'MapStringListBrandsRequest',
    as HashRef[ListBrandsRequest()];

declare 'ListBrandsResponse',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ListBrandsResponse'];

coerce 'ListBrandsResponse',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ListBrandsResponse'->new($_) };

declare 'RepeatedListBrandsResponse',
    as ArrayRef[ListBrandsResponse()];

coerce 'RepeatedListBrandsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ListBrandsResponse'->new($_) } @$_ ] };

declare 'MapStringListBrandsResponse',
    as HashRef[ListBrandsResponse()];

declare 'CreateBrandRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::CreateBrandRequest'];

coerce 'CreateBrandRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::CreateBrandRequest'->new($_) };

declare 'RepeatedCreateBrandRequest',
    as ArrayRef[CreateBrandRequest()];

coerce 'RepeatedCreateBrandRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::CreateBrandRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBrandRequest',
    as HashRef[CreateBrandRequest()];

declare 'GetBrandRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::GetBrandRequest'];

coerce 'GetBrandRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::GetBrandRequest'->new($_) };

declare 'RepeatedGetBrandRequest',
    as ArrayRef[GetBrandRequest()];

coerce 'RepeatedGetBrandRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::GetBrandRequest'->new($_) } @$_ ] };

declare 'MapStringGetBrandRequest',
    as HashRef[GetBrandRequest()];

declare 'ListIdentityAwareProxyClientsRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ListIdentityAwareProxyClientsRequest'];

coerce 'ListIdentityAwareProxyClientsRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ListIdentityAwareProxyClientsRequest'->new($_) };

declare 'RepeatedListIdentityAwareProxyClientsRequest',
    as ArrayRef[ListIdentityAwareProxyClientsRequest()];

coerce 'RepeatedListIdentityAwareProxyClientsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ListIdentityAwareProxyClientsRequest'->new($_) } @$_ ] };

declare 'MapStringListIdentityAwareProxyClientsRequest',
    as HashRef[ListIdentityAwareProxyClientsRequest()];

declare 'ListIdentityAwareProxyClientsResponse',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ListIdentityAwareProxyClientsResponse'];

coerce 'ListIdentityAwareProxyClientsResponse',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ListIdentityAwareProxyClientsResponse'->new($_) };

declare 'RepeatedListIdentityAwareProxyClientsResponse',
    as ArrayRef[ListIdentityAwareProxyClientsResponse()];

coerce 'RepeatedListIdentityAwareProxyClientsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ListIdentityAwareProxyClientsResponse'->new($_) } @$_ ] };

declare 'MapStringListIdentityAwareProxyClientsResponse',
    as HashRef[ListIdentityAwareProxyClientsResponse()];

declare 'CreateIdentityAwareProxyClientRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::CreateIdentityAwareProxyClientRequest'];

coerce 'CreateIdentityAwareProxyClientRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::CreateIdentityAwareProxyClientRequest'->new($_) };

declare 'RepeatedCreateIdentityAwareProxyClientRequest',
    as ArrayRef[CreateIdentityAwareProxyClientRequest()];

coerce 'RepeatedCreateIdentityAwareProxyClientRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::CreateIdentityAwareProxyClientRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIdentityAwareProxyClientRequest',
    as HashRef[CreateIdentityAwareProxyClientRequest()];

declare 'GetIdentityAwareProxyClientRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::GetIdentityAwareProxyClientRequest'];

coerce 'GetIdentityAwareProxyClientRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::GetIdentityAwareProxyClientRequest'->new($_) };

declare 'RepeatedGetIdentityAwareProxyClientRequest',
    as ArrayRef[GetIdentityAwareProxyClientRequest()];

coerce 'RepeatedGetIdentityAwareProxyClientRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::GetIdentityAwareProxyClientRequest'->new($_) } @$_ ] };

declare 'MapStringGetIdentityAwareProxyClientRequest',
    as HashRef[GetIdentityAwareProxyClientRequest()];

declare 'ResetIdentityAwareProxyClientSecretRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::ResetIdentityAwareProxyClientSecretRequest'];

coerce 'ResetIdentityAwareProxyClientSecretRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::ResetIdentityAwareProxyClientSecretRequest'->new($_) };

declare 'RepeatedResetIdentityAwareProxyClientSecretRequest',
    as ArrayRef[ResetIdentityAwareProxyClientSecretRequest()];

coerce 'RepeatedResetIdentityAwareProxyClientSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::ResetIdentityAwareProxyClientSecretRequest'->new($_) } @$_ ] };

declare 'MapStringResetIdentityAwareProxyClientSecretRequest',
    as HashRef[ResetIdentityAwareProxyClientSecretRequest()];

declare 'DeleteIdentityAwareProxyClientRequest',
    as InstanceOf['Google::Cloud::Iap::V1::Service::DeleteIdentityAwareProxyClientRequest'];

coerce 'DeleteIdentityAwareProxyClientRequest',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::DeleteIdentityAwareProxyClientRequest'->new($_) };

declare 'RepeatedDeleteIdentityAwareProxyClientRequest',
    as ArrayRef[DeleteIdentityAwareProxyClientRequest()];

coerce 'RepeatedDeleteIdentityAwareProxyClientRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::DeleteIdentityAwareProxyClientRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIdentityAwareProxyClientRequest',
    as HashRef[DeleteIdentityAwareProxyClientRequest()];

declare 'Brand',
    as InstanceOf['Google::Cloud::Iap::V1::Service::Brand'];

coerce 'Brand',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::Brand'->new($_) };

declare 'RepeatedBrand',
    as ArrayRef[Brand()];

coerce 'RepeatedBrand',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::Brand'->new($_) } @$_ ] };

declare 'MapStringBrand',
    as HashRef[Brand()];

declare 'IdentityAwareProxyClient',
    as InstanceOf['Google::Cloud::Iap::V1::Service::IdentityAwareProxyClient'];

coerce 'IdentityAwareProxyClient',
    from HashRef, via { 'Google::Cloud::Iap::V1::Service::IdentityAwareProxyClient'->new($_) };

declare 'RepeatedIdentityAwareProxyClient',
    as ArrayRef[IdentityAwareProxyClient()];

coerce 'RepeatedIdentityAwareProxyClient',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iap::V1::Service::IdentityAwareProxyClient'->new($_) } @$_ ] };

declare 'MapStringIdentityAwareProxyClient',
    as HashRef[IdentityAwareProxyClient()];

1;

__END__

=head1 NAME

Google::Cloud::Iap::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
