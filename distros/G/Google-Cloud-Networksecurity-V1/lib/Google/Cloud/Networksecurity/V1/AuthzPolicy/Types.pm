package Google::Cloud::Networksecurity::V1::AuthzPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AuthzPolicy',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy'];

coerce 'AuthzPolicy',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy'->new($_) };

declare 'RepeatedAuthzPolicy',
    as ArrayRef[AuthzPolicy()];

coerce 'RepeatedAuthzPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy'->new($_) } @$_ ] };

declare 'MapStringAuthzPolicy',
    as HashRef[AuthzPolicy()];

declare 'LoadBalancingScheme',
    as (Int | Str);

declare 'AuthzAction',
    as (Int | Str);

declare 'PolicyProfile',
    as (Int | Str);

declare 'Target',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::Target'];

coerce 'Target',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::Target'->new($_) };

declare 'RepeatedTarget',
    as ArrayRef[Target()];

coerce 'RepeatedTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::Target'->new($_) } @$_ ] };

declare 'MapStringTarget',
    as HashRef[Target()];

declare 'AuthzRule',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule'];

coerce 'AuthzRule',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule'->new($_) };

declare 'RepeatedAuthzRule',
    as ArrayRef[AuthzRule()];

coerce 'RepeatedAuthzRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule'->new($_) } @$_ ] };

declare 'MapStringAuthzRule',
    as HashRef[AuthzRule()];

declare 'StringMatch',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::StringMatch'];

coerce 'StringMatch',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::StringMatch'->new($_) };

declare 'RepeatedStringMatch',
    as ArrayRef[StringMatch()];

coerce 'RepeatedStringMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::StringMatch'->new($_) } @$_ ] };

declare 'MapStringStringMatch',
    as HashRef[StringMatch()];

declare 'IpBlock',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::IpBlock'];

coerce 'IpBlock',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::IpBlock'->new($_) };

declare 'RepeatedIpBlock',
    as ArrayRef[IpBlock()];

coerce 'RepeatedIpBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::IpBlock'->new($_) } @$_ ] };

declare 'MapStringIpBlock',
    as HashRef[IpBlock()];

declare 'RequestResource',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::RequestResource'];

coerce 'RequestResource',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::RequestResource'->new($_) };

declare 'RepeatedRequestResource',
    as ArrayRef[RequestResource()];

coerce 'RepeatedRequestResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::RequestResource'->new($_) } @$_ ] };

declare 'MapStringRequestResource',
    as HashRef[RequestResource()];

declare 'TagValueIdSet',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::RequestResource::TagValueIdSet'];

coerce 'TagValueIdSet',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::RequestResource::TagValueIdSet'->new($_) };

declare 'RepeatedTagValueIdSet',
    as ArrayRef[TagValueIdSet()];

coerce 'RepeatedTagValueIdSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::RequestResource::TagValueIdSet'->new($_) } @$_ ] };

declare 'MapStringTagValueIdSet',
    as HashRef[TagValueIdSet()];

declare 'HeaderMatch',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::HeaderMatch'];

coerce 'HeaderMatch',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::HeaderMatch'->new($_) };

declare 'RepeatedHeaderMatch',
    as ArrayRef[HeaderMatch()];

coerce 'RepeatedHeaderMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::HeaderMatch'->new($_) } @$_ ] };

declare 'MapStringHeaderMatch',
    as HashRef[HeaderMatch()];

declare 'Principal',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::Principal'];

coerce 'Principal',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::Principal'->new($_) };

declare 'RepeatedPrincipal',
    as ArrayRef[Principal()];

coerce 'RepeatedPrincipal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::Principal'->new($_) } @$_ ] };

declare 'MapStringPrincipal',
    as HashRef[Principal()];

declare 'PrincipalSelector',
    as (Int | Str);

declare 'From',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::From'];

coerce 'From',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::From'->new($_) };

declare 'RepeatedFrom',
    as ArrayRef[From()];

coerce 'RepeatedFrom',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::From'->new($_) } @$_ ] };

declare 'MapStringFrom',
    as HashRef[From()];

declare 'RequestSource',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::From::RequestSource'];

coerce 'RequestSource',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::From::RequestSource'->new($_) };

declare 'RepeatedRequestSource',
    as ArrayRef[RequestSource()];

coerce 'RepeatedRequestSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::From::RequestSource'->new($_) } @$_ ] };

declare 'MapStringRequestSource',
    as HashRef[RequestSource()];

declare 'To',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To'];

coerce 'To',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To'->new($_) };

declare 'RepeatedTo',
    as ArrayRef[To()];

coerce 'RepeatedTo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To'->new($_) } @$_ ] };

declare 'MapStringTo',
    as HashRef[To()];

declare 'RequestOperation',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation'];

coerce 'RequestOperation',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation'->new($_) };

declare 'RepeatedRequestOperation',
    as ArrayRef[RequestOperation()];

coerce 'RepeatedRequestOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation'->new($_) } @$_ ] };

declare 'MapStringRequestOperation',
    as HashRef[RequestOperation()];

declare 'BaseProtocolMethodsOption',
    as (Int | Str);

declare 'HeaderSet',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation::HeaderSet'];

coerce 'HeaderSet',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation::HeaderSet'->new($_) };

declare 'RepeatedHeaderSet',
    as ArrayRef[HeaderSet()];

coerce 'RepeatedHeaderSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation::HeaderSet'->new($_) } @$_ ] };

declare 'MapStringHeaderSet',
    as HashRef[HeaderSet()];

declare 'MCPMethod',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation::MCPMethod'];

coerce 'MCPMethod',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation::MCPMethod'->new($_) };

declare 'RepeatedMCPMethod',
    as ArrayRef[MCPMethod()];

coerce 'RepeatedMCPMethod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation::MCPMethod'->new($_) } @$_ ] };

declare 'MapStringMCPMethod',
    as HashRef[MCPMethod()];

declare 'MCP',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation::MCP'];

coerce 'MCP',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation::MCP'->new($_) };

declare 'RepeatedMCP',
    as ArrayRef[MCP()];

coerce 'RepeatedMCP',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::AuthzRule::To::RequestOperation::MCP'->new($_) } @$_ ] };

declare 'MapStringMCP',
    as HashRef[MCP()];

declare 'CustomProvider',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::CustomProvider'];

coerce 'CustomProvider',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::CustomProvider'->new($_) };

declare 'RepeatedCustomProvider',
    as ArrayRef[CustomProvider()];

coerce 'RepeatedCustomProvider',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::CustomProvider'->new($_) } @$_ ] };

declare 'MapStringCustomProvider',
    as HashRef[CustomProvider()];

declare 'CloudIap',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::CustomProvider::CloudIap'];

coerce 'CloudIap',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::CustomProvider::CloudIap'->new($_) };

declare 'RepeatedCloudIap',
    as ArrayRef[CloudIap()];

coerce 'RepeatedCloudIap',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::CustomProvider::CloudIap'->new($_) } @$_ ] };

declare 'MapStringCloudIap',
    as HashRef[CloudIap()];

declare 'AuthzExtension',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::CustomProvider::AuthzExtension'];

coerce 'AuthzExtension',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::CustomProvider::AuthzExtension'->new($_) };

declare 'RepeatedAuthzExtension',
    as ArrayRef[AuthzExtension()];

coerce 'RepeatedAuthzExtension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::CustomProvider::AuthzExtension'->new($_) } @$_ ] };

declare 'MapStringAuthzExtension',
    as HashRef[AuthzExtension()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::AuthzPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateAuthzPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::CreateAuthzPolicyRequest'];

coerce 'CreateAuthzPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::CreateAuthzPolicyRequest'->new($_) };

declare 'RepeatedCreateAuthzPolicyRequest',
    as ArrayRef[CreateAuthzPolicyRequest()];

coerce 'RepeatedCreateAuthzPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::CreateAuthzPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAuthzPolicyRequest',
    as HashRef[CreateAuthzPolicyRequest()];

declare 'ListAuthzPoliciesRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::ListAuthzPoliciesRequest'];

coerce 'ListAuthzPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::ListAuthzPoliciesRequest'->new($_) };

declare 'RepeatedListAuthzPoliciesRequest',
    as ArrayRef[ListAuthzPoliciesRequest()];

coerce 'RepeatedListAuthzPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::ListAuthzPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListAuthzPoliciesRequest',
    as HashRef[ListAuthzPoliciesRequest()];

declare 'ListAuthzPoliciesResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::ListAuthzPoliciesResponse'];

coerce 'ListAuthzPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::ListAuthzPoliciesResponse'->new($_) };

declare 'RepeatedListAuthzPoliciesResponse',
    as ArrayRef[ListAuthzPoliciesResponse()];

coerce 'RepeatedListAuthzPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::ListAuthzPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListAuthzPoliciesResponse',
    as HashRef[ListAuthzPoliciesResponse()];

declare 'GetAuthzPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::GetAuthzPolicyRequest'];

coerce 'GetAuthzPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::GetAuthzPolicyRequest'->new($_) };

declare 'RepeatedGetAuthzPolicyRequest',
    as ArrayRef[GetAuthzPolicyRequest()];

coerce 'RepeatedGetAuthzPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::GetAuthzPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuthzPolicyRequest',
    as HashRef[GetAuthzPolicyRequest()];

declare 'UpdateAuthzPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::UpdateAuthzPolicyRequest'];

coerce 'UpdateAuthzPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::UpdateAuthzPolicyRequest'->new($_) };

declare 'RepeatedUpdateAuthzPolicyRequest',
    as ArrayRef[UpdateAuthzPolicyRequest()];

coerce 'RepeatedUpdateAuthzPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::UpdateAuthzPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAuthzPolicyRequest',
    as HashRef[UpdateAuthzPolicyRequest()];

declare 'DeleteAuthzPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthzPolicy::DeleteAuthzPolicyRequest'];

coerce 'DeleteAuthzPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::DeleteAuthzPolicyRequest'->new($_) };

declare 'RepeatedDeleteAuthzPolicyRequest',
    as ArrayRef[DeleteAuthzPolicyRequest()];

coerce 'RepeatedDeleteAuthzPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthzPolicy::DeleteAuthzPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAuthzPolicyRequest',
    as HashRef[DeleteAuthzPolicyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::AuthzPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
