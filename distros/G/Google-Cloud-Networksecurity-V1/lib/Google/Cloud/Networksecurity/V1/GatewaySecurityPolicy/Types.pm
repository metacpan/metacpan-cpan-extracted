package Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GatewaySecurityPolicy',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GatewaySecurityPolicy'];

coerce 'GatewaySecurityPolicy',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GatewaySecurityPolicy'->new($_) };

declare 'RepeatedGatewaySecurityPolicy',
    as ArrayRef[GatewaySecurityPolicy()];

coerce 'RepeatedGatewaySecurityPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GatewaySecurityPolicy'->new($_) } @$_ ] };

declare 'MapStringGatewaySecurityPolicy',
    as HashRef[GatewaySecurityPolicy()];

declare 'CreateGatewaySecurityPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::CreateGatewaySecurityPolicyRequest'];

coerce 'CreateGatewaySecurityPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::CreateGatewaySecurityPolicyRequest'->new($_) };

declare 'RepeatedCreateGatewaySecurityPolicyRequest',
    as ArrayRef[CreateGatewaySecurityPolicyRequest()];

coerce 'RepeatedCreateGatewaySecurityPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::CreateGatewaySecurityPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGatewaySecurityPolicyRequest',
    as HashRef[CreateGatewaySecurityPolicyRequest()];

declare 'ListGatewaySecurityPoliciesRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::ListGatewaySecurityPoliciesRequest'];

coerce 'ListGatewaySecurityPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::ListGatewaySecurityPoliciesRequest'->new($_) };

declare 'RepeatedListGatewaySecurityPoliciesRequest',
    as ArrayRef[ListGatewaySecurityPoliciesRequest()];

coerce 'RepeatedListGatewaySecurityPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::ListGatewaySecurityPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListGatewaySecurityPoliciesRequest',
    as HashRef[ListGatewaySecurityPoliciesRequest()];

declare 'ListGatewaySecurityPoliciesResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::ListGatewaySecurityPoliciesResponse'];

coerce 'ListGatewaySecurityPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::ListGatewaySecurityPoliciesResponse'->new($_) };

declare 'RepeatedListGatewaySecurityPoliciesResponse',
    as ArrayRef[ListGatewaySecurityPoliciesResponse()];

coerce 'RepeatedListGatewaySecurityPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::ListGatewaySecurityPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListGatewaySecurityPoliciesResponse',
    as HashRef[ListGatewaySecurityPoliciesResponse()];

declare 'GetGatewaySecurityPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GetGatewaySecurityPolicyRequest'];

coerce 'GetGatewaySecurityPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GetGatewaySecurityPolicyRequest'->new($_) };

declare 'RepeatedGetGatewaySecurityPolicyRequest',
    as ArrayRef[GetGatewaySecurityPolicyRequest()];

coerce 'RepeatedGetGatewaySecurityPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GetGatewaySecurityPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetGatewaySecurityPolicyRequest',
    as HashRef[GetGatewaySecurityPolicyRequest()];

declare 'DeleteGatewaySecurityPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::DeleteGatewaySecurityPolicyRequest'];

coerce 'DeleteGatewaySecurityPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::DeleteGatewaySecurityPolicyRequest'->new($_) };

declare 'RepeatedDeleteGatewaySecurityPolicyRequest',
    as ArrayRef[DeleteGatewaySecurityPolicyRequest()];

coerce 'RepeatedDeleteGatewaySecurityPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::DeleteGatewaySecurityPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGatewaySecurityPolicyRequest',
    as HashRef[DeleteGatewaySecurityPolicyRequest()];

declare 'UpdateGatewaySecurityPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::UpdateGatewaySecurityPolicyRequest'];

coerce 'UpdateGatewaySecurityPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::UpdateGatewaySecurityPolicyRequest'->new($_) };

declare 'RepeatedUpdateGatewaySecurityPolicyRequest',
    as ArrayRef[UpdateGatewaySecurityPolicyRequest()];

coerce 'RepeatedUpdateGatewaySecurityPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::UpdateGatewaySecurityPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGatewaySecurityPolicyRequest',
    as HashRef[UpdateGatewaySecurityPolicyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
