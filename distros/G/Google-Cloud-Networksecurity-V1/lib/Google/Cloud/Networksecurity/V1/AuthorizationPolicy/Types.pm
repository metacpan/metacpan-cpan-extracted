package Google::Cloud::Networksecurity::V1::AuthorizationPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AuthorizationPolicy',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy'];

coerce 'AuthorizationPolicy',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy'->new($_) };

declare 'RepeatedAuthorizationPolicy',
    as ArrayRef[AuthorizationPolicy()];

coerce 'RepeatedAuthorizationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy'->new($_) } @$_ ] };

declare 'MapStringAuthorizationPolicy',
    as HashRef[AuthorizationPolicy()];

declare 'Action',
    as (Int | Str);

declare 'Rule',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule'];

coerce 'Rule',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule'->new($_) };

declare 'RepeatedRule',
    as ArrayRef[Rule()];

coerce 'RepeatedRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule'->new($_) } @$_ ] };

declare 'MapStringRule',
    as HashRef[Rule()];

declare 'Source',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule::Source'];

coerce 'Source',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule::Source'->new($_) };

declare 'RepeatedSource',
    as ArrayRef[Source()];

coerce 'RepeatedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule::Source'->new($_) } @$_ ] };

declare 'MapStringSource',
    as HashRef[Source()];

declare 'Destination',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule::Destination'];

coerce 'Destination',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule::Destination'->new($_) };

declare 'RepeatedDestination',
    as ArrayRef[Destination()];

coerce 'RepeatedDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule::Destination'->new($_) } @$_ ] };

declare 'MapStringDestination',
    as HashRef[Destination()];

declare 'HttpHeaderMatch',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule::Destination::HttpHeaderMatch'];

coerce 'HttpHeaderMatch',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule::Destination::HttpHeaderMatch'->new($_) };

declare 'RepeatedHttpHeaderMatch',
    as ArrayRef[HttpHeaderMatch()];

coerce 'RepeatedHttpHeaderMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule::Destination::HttpHeaderMatch'->new($_) } @$_ ] };

declare 'MapStringHttpHeaderMatch',
    as HashRef[HttpHeaderMatch()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListAuthorizationPoliciesRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesRequest'];

coerce 'ListAuthorizationPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesRequest'->new($_) };

declare 'RepeatedListAuthorizationPoliciesRequest',
    as ArrayRef[ListAuthorizationPoliciesRequest()];

coerce 'RepeatedListAuthorizationPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListAuthorizationPoliciesRequest',
    as HashRef[ListAuthorizationPoliciesRequest()];

declare 'ListAuthorizationPoliciesResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse'];

coerce 'ListAuthorizationPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse'->new($_) };

declare 'RepeatedListAuthorizationPoliciesResponse',
    as ArrayRef[ListAuthorizationPoliciesResponse()];

coerce 'RepeatedListAuthorizationPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListAuthorizationPoliciesResponse',
    as HashRef[ListAuthorizationPoliciesResponse()];

declare 'GetAuthorizationPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::GetAuthorizationPolicyRequest'];

coerce 'GetAuthorizationPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::GetAuthorizationPolicyRequest'->new($_) };

declare 'RepeatedGetAuthorizationPolicyRequest',
    as ArrayRef[GetAuthorizationPolicyRequest()];

coerce 'RepeatedGetAuthorizationPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::GetAuthorizationPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuthorizationPolicyRequest',
    as HashRef[GetAuthorizationPolicyRequest()];

declare 'CreateAuthorizationPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::CreateAuthorizationPolicyRequest'];

coerce 'CreateAuthorizationPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::CreateAuthorizationPolicyRequest'->new($_) };

declare 'RepeatedCreateAuthorizationPolicyRequest',
    as ArrayRef[CreateAuthorizationPolicyRequest()];

coerce 'RepeatedCreateAuthorizationPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::CreateAuthorizationPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAuthorizationPolicyRequest',
    as HashRef[CreateAuthorizationPolicyRequest()];

declare 'UpdateAuthorizationPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::UpdateAuthorizationPolicyRequest'];

coerce 'UpdateAuthorizationPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::UpdateAuthorizationPolicyRequest'->new($_) };

declare 'RepeatedUpdateAuthorizationPolicyRequest',
    as ArrayRef[UpdateAuthorizationPolicyRequest()];

coerce 'RepeatedUpdateAuthorizationPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::UpdateAuthorizationPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAuthorizationPolicyRequest',
    as HashRef[UpdateAuthorizationPolicyRequest()];

declare 'DeleteAuthorizationPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AuthorizationPolicy::DeleteAuthorizationPolicyRequest'];

coerce 'DeleteAuthorizationPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::DeleteAuthorizationPolicyRequest'->new($_) };

declare 'RepeatedDeleteAuthorizationPolicyRequest',
    as ArrayRef[DeleteAuthorizationPolicyRequest()];

coerce 'RepeatedDeleteAuthorizationPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::DeleteAuthorizationPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAuthorizationPolicyRequest',
    as HashRef[DeleteAuthorizationPolicyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::AuthorizationPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
