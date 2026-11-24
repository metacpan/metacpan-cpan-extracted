package Google::Cloud::Agentidentity::V1::AuthProviderService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AuthProviderType',
    as (Int | Str);

declare 'AuthProvider',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::AuthProvider'];

coerce 'AuthProvider',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::AuthProvider'->new($_) };

declare 'RepeatedAuthProvider',
    as ArrayRef[AuthProvider()];

coerce 'RepeatedAuthProvider',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::AuthProvider'->new($_) } @$_ ] };

declare 'MapStringAuthProvider',
    as HashRef[AuthProvider()];

declare 'State',
    as (Int | Str);

declare 'AuthProviderTypeParams',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::AuthProvider::AuthProviderTypeParams'];

coerce 'AuthProviderTypeParams',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::AuthProvider::AuthProviderTypeParams'->new($_) };

declare 'RepeatedAuthProviderTypeParams',
    as ArrayRef[AuthProviderTypeParams()];

coerce 'RepeatedAuthProviderTypeParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::AuthProvider::AuthProviderTypeParams'->new($_) } @$_ ] };

declare 'MapStringAuthProviderTypeParams',
    as HashRef[AuthProviderTypeParams()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::AuthProvider::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::AuthProvider::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::AuthProvider::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ThreeLeggedOAuth',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::ThreeLeggedOAuth'];

coerce 'ThreeLeggedOAuth',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ThreeLeggedOAuth'->new($_) };

declare 'RepeatedThreeLeggedOAuth',
    as ArrayRef[ThreeLeggedOAuth()];

coerce 'RepeatedThreeLeggedOAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ThreeLeggedOAuth'->new($_) } @$_ ] };

declare 'MapStringThreeLeggedOAuth',
    as HashRef[ThreeLeggedOAuth()];

declare 'TwoLeggedOAuth',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::TwoLeggedOAuth'];

coerce 'TwoLeggedOAuth',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::TwoLeggedOAuth'->new($_) };

declare 'RepeatedTwoLeggedOAuth',
    as ArrayRef[TwoLeggedOAuth()];

coerce 'RepeatedTwoLeggedOAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::TwoLeggedOAuth'->new($_) } @$_ ] };

declare 'MapStringTwoLeggedOAuth',
    as HashRef[TwoLeggedOAuth()];

declare 'ApiKeyParams',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::ApiKeyParams'];

coerce 'ApiKeyParams',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ApiKeyParams'->new($_) };

declare 'RepeatedApiKeyParams',
    as ArrayRef[ApiKeyParams()];

coerce 'RepeatedApiKeyParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ApiKeyParams'->new($_) } @$_ ] };

declare 'MapStringApiKeyParams',
    as HashRef[ApiKeyParams()];

declare 'GeminiEnterpriseAuthProviderParams',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::GeminiEnterpriseAuthProviderParams'];

coerce 'GeminiEnterpriseAuthProviderParams',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::GeminiEnterpriseAuthProviderParams'->new($_) };

declare 'RepeatedGeminiEnterpriseAuthProviderParams',
    as ArrayRef[GeminiEnterpriseAuthProviderParams()];

coerce 'RepeatedGeminiEnterpriseAuthProviderParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::GeminiEnterpriseAuthProviderParams'->new($_) } @$_ ] };

declare 'MapStringGeminiEnterpriseAuthProviderParams',
    as HashRef[GeminiEnterpriseAuthProviderParams()];

declare 'ListAuthProvidersRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthProvidersRequest'];

coerce 'ListAuthProvidersRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthProvidersRequest'->new($_) };

declare 'RepeatedListAuthProvidersRequest',
    as ArrayRef[ListAuthProvidersRequest()];

coerce 'RepeatedListAuthProvidersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthProvidersRequest'->new($_) } @$_ ] };

declare 'MapStringListAuthProvidersRequest',
    as HashRef[ListAuthProvidersRequest()];

declare 'ListAuthProvidersResponse',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthProvidersResponse'];

coerce 'ListAuthProvidersResponse',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthProvidersResponse'->new($_) };

declare 'RepeatedListAuthProvidersResponse',
    as ArrayRef[ListAuthProvidersResponse()];

coerce 'RepeatedListAuthProvidersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthProvidersResponse'->new($_) } @$_ ] };

declare 'MapStringListAuthProvidersResponse',
    as HashRef[ListAuthProvidersResponse()];

declare 'GetAuthProviderRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::GetAuthProviderRequest'];

coerce 'GetAuthProviderRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::GetAuthProviderRequest'->new($_) };

declare 'RepeatedGetAuthProviderRequest',
    as ArrayRef[GetAuthProviderRequest()];

coerce 'RepeatedGetAuthProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::GetAuthProviderRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuthProviderRequest',
    as HashRef[GetAuthProviderRequest()];

declare 'CreateAuthProviderRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::CreateAuthProviderRequest'];

coerce 'CreateAuthProviderRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::CreateAuthProviderRequest'->new($_) };

declare 'RepeatedCreateAuthProviderRequest',
    as ArrayRef[CreateAuthProviderRequest()];

coerce 'RepeatedCreateAuthProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::CreateAuthProviderRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAuthProviderRequest',
    as HashRef[CreateAuthProviderRequest()];

declare 'UpdateAuthProviderRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::UpdateAuthProviderRequest'];

coerce 'UpdateAuthProviderRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::UpdateAuthProviderRequest'->new($_) };

declare 'RepeatedUpdateAuthProviderRequest',
    as ArrayRef[UpdateAuthProviderRequest()];

coerce 'RepeatedUpdateAuthProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::UpdateAuthProviderRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAuthProviderRequest',
    as HashRef[UpdateAuthProviderRequest()];

declare 'DeleteAuthProviderRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::DeleteAuthProviderRequest'];

coerce 'DeleteAuthProviderRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::DeleteAuthProviderRequest'->new($_) };

declare 'RepeatedDeleteAuthProviderRequest',
    as ArrayRef[DeleteAuthProviderRequest()];

coerce 'RepeatedDeleteAuthProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::DeleteAuthProviderRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAuthProviderRequest',
    as HashRef[DeleteAuthProviderRequest()];

declare 'UndeleteAuthProviderRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::UndeleteAuthProviderRequest'];

coerce 'UndeleteAuthProviderRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::UndeleteAuthProviderRequest'->new($_) };

declare 'RepeatedUndeleteAuthProviderRequest',
    as ArrayRef[UndeleteAuthProviderRequest()];

coerce 'RepeatedUndeleteAuthProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::UndeleteAuthProviderRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteAuthProviderRequest',
    as HashRef[UndeleteAuthProviderRequest()];

declare 'EnableAuthProviderRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::EnableAuthProviderRequest'];

coerce 'EnableAuthProviderRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::EnableAuthProviderRequest'->new($_) };

declare 'RepeatedEnableAuthProviderRequest',
    as ArrayRef[EnableAuthProviderRequest()];

coerce 'RepeatedEnableAuthProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::EnableAuthProviderRequest'->new($_) } @$_ ] };

declare 'MapStringEnableAuthProviderRequest',
    as HashRef[EnableAuthProviderRequest()];

declare 'DisableAuthProviderRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::DisableAuthProviderRequest'];

coerce 'DisableAuthProviderRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::DisableAuthProviderRequest'->new($_) };

declare 'RepeatedDisableAuthProviderRequest',
    as ArrayRef[DisableAuthProviderRequest()];

coerce 'RepeatedDisableAuthProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::DisableAuthProviderRequest'->new($_) } @$_ ] };

declare 'MapStringDisableAuthProviderRequest',
    as HashRef[DisableAuthProviderRequest()];

declare 'Authorization',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::Authorization'];

coerce 'Authorization',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::Authorization'->new($_) };

declare 'RepeatedAuthorization',
    as ArrayRef[Authorization()];

coerce 'RepeatedAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::Authorization'->new($_) } @$_ ] };

declare 'MapStringAuthorization',
    as HashRef[Authorization()];

declare 'State',
    as (Int | Str);

declare 'ListAuthorizationsRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthorizationsRequest'];

coerce 'ListAuthorizationsRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthorizationsRequest'->new($_) };

declare 'RepeatedListAuthorizationsRequest',
    as ArrayRef[ListAuthorizationsRequest()];

coerce 'RepeatedListAuthorizationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthorizationsRequest'->new($_) } @$_ ] };

declare 'MapStringListAuthorizationsRequest',
    as HashRef[ListAuthorizationsRequest()];

declare 'ListAuthorizationsResponse',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthorizationsResponse'];

coerce 'ListAuthorizationsResponse',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthorizationsResponse'->new($_) };

declare 'RepeatedListAuthorizationsResponse',
    as ArrayRef[ListAuthorizationsResponse()];

coerce 'RepeatedListAuthorizationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAuthorizationsResponse'->new($_) } @$_ ] };

declare 'MapStringListAuthorizationsResponse',
    as HashRef[ListAuthorizationsResponse()];

declare 'GetAuthorizationRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::GetAuthorizationRequest'];

coerce 'GetAuthorizationRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::GetAuthorizationRequest'->new($_) };

declare 'RepeatedGetAuthorizationRequest',
    as ArrayRef[GetAuthorizationRequest()];

coerce 'RepeatedGetAuthorizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::GetAuthorizationRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuthorizationRequest',
    as HashRef[GetAuthorizationRequest()];

declare 'DeleteAuthorizationRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::DeleteAuthorizationRequest'];

coerce 'DeleteAuthorizationRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::DeleteAuthorizationRequest'->new($_) };

declare 'RepeatedDeleteAuthorizationRequest',
    as ArrayRef[DeleteAuthorizationRequest()];

coerce 'RepeatedDeleteAuthorizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::DeleteAuthorizationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAuthorizationRequest',
    as HashRef[DeleteAuthorizationRequest()];

declare 'AccessSummary',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::AccessSummary'];

coerce 'AccessSummary',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::AccessSummary'->new($_) };

declare 'RepeatedAccessSummary',
    as ArrayRef[AccessSummary()];

coerce 'RepeatedAccessSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::AccessSummary'->new($_) } @$_ ] };

declare 'MapStringAccessSummary',
    as HashRef[AccessSummary()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::AccessSummary::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::AccessSummary::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::AccessSummary::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListAccessSummariesRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::ListAccessSummariesRequest'];

coerce 'ListAccessSummariesRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAccessSummariesRequest'->new($_) };

declare 'RepeatedListAccessSummariesRequest',
    as ArrayRef[ListAccessSummariesRequest()];

coerce 'RepeatedListAccessSummariesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAccessSummariesRequest'->new($_) } @$_ ] };

declare 'MapStringListAccessSummariesRequest',
    as HashRef[ListAccessSummariesRequest()];

declare 'ListAccessSummariesResponse',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::ListAccessSummariesResponse'];

coerce 'ListAccessSummariesResponse',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAccessSummariesResponse'->new($_) };

declare 'RepeatedListAccessSummariesResponse',
    as ArrayRef[ListAccessSummariesResponse()];

coerce 'RepeatedListAccessSummariesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::ListAccessSummariesResponse'->new($_) } @$_ ] };

declare 'MapStringListAccessSummariesResponse',
    as HashRef[ListAccessSummariesResponse()];

declare 'GetAccessSummaryRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::GetAccessSummaryRequest'];

coerce 'GetAccessSummaryRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::GetAccessSummaryRequest'->new($_) };

declare 'RepeatedGetAccessSummaryRequest',
    as ArrayRef[GetAccessSummaryRequest()];

coerce 'RepeatedGetAccessSummaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::GetAccessSummaryRequest'->new($_) } @$_ ] };

declare 'MapStringGetAccessSummaryRequest',
    as HashRef[GetAccessSummaryRequest()];

declare 'QueryAuthProvidersRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::QueryAuthProvidersRequest'];

coerce 'QueryAuthProvidersRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::QueryAuthProvidersRequest'->new($_) };

declare 'RepeatedQueryAuthProvidersRequest',
    as ArrayRef[QueryAuthProvidersRequest()];

coerce 'RepeatedQueryAuthProvidersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::QueryAuthProvidersRequest'->new($_) } @$_ ] };

declare 'MapStringQueryAuthProvidersRequest',
    as HashRef[QueryAuthProvidersRequest()];

declare 'QueryAuthProvidersResponse',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::QueryAuthProvidersResponse'];

coerce 'QueryAuthProvidersResponse',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::QueryAuthProvidersResponse'->new($_) };

declare 'RepeatedQueryAuthProvidersResponse',
    as ArrayRef[QueryAuthProvidersResponse()];

coerce 'RepeatedQueryAuthProvidersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::QueryAuthProvidersResponse'->new($_) } @$_ ] };

declare 'MapStringQueryAuthProvidersResponse',
    as HashRef[QueryAuthProvidersResponse()];

declare 'QueryWorkloadsRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::QueryWorkloadsRequest'];

coerce 'QueryWorkloadsRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::QueryWorkloadsRequest'->new($_) };

declare 'RepeatedQueryWorkloadsRequest',
    as ArrayRef[QueryWorkloadsRequest()];

coerce 'RepeatedQueryWorkloadsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::QueryWorkloadsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryWorkloadsRequest',
    as HashRef[QueryWorkloadsRequest()];

declare 'QueryWorkloadsResponse',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::QueryWorkloadsResponse'];

coerce 'QueryWorkloadsResponse',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::QueryWorkloadsResponse'->new($_) };

declare 'RepeatedQueryWorkloadsResponse',
    as ArrayRef[QueryWorkloadsResponse()];

coerce 'RepeatedQueryWorkloadsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::QueryWorkloadsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryWorkloadsResponse',
    as HashRef[QueryWorkloadsResponse()];

declare 'RevokeAuthorizationRequest',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::RevokeAuthorizationRequest'];

coerce 'RevokeAuthorizationRequest',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::RevokeAuthorizationRequest'->new($_) };

declare 'RepeatedRevokeAuthorizationRequest',
    as ArrayRef[RevokeAuthorizationRequest()];

coerce 'RepeatedRevokeAuthorizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::RevokeAuthorizationRequest'->new($_) } @$_ ] };

declare 'MapStringRevokeAuthorizationRequest',
    as HashRef[RevokeAuthorizationRequest()];

declare 'RevokeAuthorizationResponse',
    as InstanceOf['Google::Cloud::Agentidentity::V1::AuthProviderService::RevokeAuthorizationResponse'];

coerce 'RevokeAuthorizationResponse',
    from HashRef, via { 'Google::Cloud::Agentidentity::V1::AuthProviderService::RevokeAuthorizationResponse'->new($_) };

declare 'RepeatedRevokeAuthorizationResponse',
    as ArrayRef[RevokeAuthorizationResponse()];

coerce 'RepeatedRevokeAuthorizationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentidentity::V1::AuthProviderService::RevokeAuthorizationResponse'->new($_) } @$_ ] };

declare 'MapStringRevokeAuthorizationResponse',
    as HashRef[RevokeAuthorizationResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Agentidentity::V1::AuthProviderService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
