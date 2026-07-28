package Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GatewaySecurityPolicyRule',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GatewaySecurityPolicyRule'];

coerce 'GatewaySecurityPolicyRule',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GatewaySecurityPolicyRule'->new($_) };

declare 'RepeatedGatewaySecurityPolicyRule',
    as ArrayRef[GatewaySecurityPolicyRule()];

coerce 'RepeatedGatewaySecurityPolicyRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GatewaySecurityPolicyRule'->new($_) } @$_ ] };

declare 'MapStringGatewaySecurityPolicyRule',
    as HashRef[GatewaySecurityPolicyRule()];

declare 'BasicProfile',
    as (Int | Str);

declare 'CreateGatewaySecurityPolicyRuleRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::CreateGatewaySecurityPolicyRuleRequest'];

coerce 'CreateGatewaySecurityPolicyRuleRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::CreateGatewaySecurityPolicyRuleRequest'->new($_) };

declare 'RepeatedCreateGatewaySecurityPolicyRuleRequest',
    as ArrayRef[CreateGatewaySecurityPolicyRuleRequest()];

coerce 'RepeatedCreateGatewaySecurityPolicyRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::CreateGatewaySecurityPolicyRuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGatewaySecurityPolicyRuleRequest',
    as HashRef[CreateGatewaySecurityPolicyRuleRequest()];

declare 'GetGatewaySecurityPolicyRuleRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GetGatewaySecurityPolicyRuleRequest'];

coerce 'GetGatewaySecurityPolicyRuleRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GetGatewaySecurityPolicyRuleRequest'->new($_) };

declare 'RepeatedGetGatewaySecurityPolicyRuleRequest',
    as ArrayRef[GetGatewaySecurityPolicyRuleRequest()];

coerce 'RepeatedGetGatewaySecurityPolicyRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GetGatewaySecurityPolicyRuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetGatewaySecurityPolicyRuleRequest',
    as HashRef[GetGatewaySecurityPolicyRuleRequest()];

declare 'UpdateGatewaySecurityPolicyRuleRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::UpdateGatewaySecurityPolicyRuleRequest'];

coerce 'UpdateGatewaySecurityPolicyRuleRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::UpdateGatewaySecurityPolicyRuleRequest'->new($_) };

declare 'RepeatedUpdateGatewaySecurityPolicyRuleRequest',
    as ArrayRef[UpdateGatewaySecurityPolicyRuleRequest()];

coerce 'RepeatedUpdateGatewaySecurityPolicyRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::UpdateGatewaySecurityPolicyRuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGatewaySecurityPolicyRuleRequest',
    as HashRef[UpdateGatewaySecurityPolicyRuleRequest()];

declare 'ListGatewaySecurityPolicyRulesRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesRequest'];

coerce 'ListGatewaySecurityPolicyRulesRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesRequest'->new($_) };

declare 'RepeatedListGatewaySecurityPolicyRulesRequest',
    as ArrayRef[ListGatewaySecurityPolicyRulesRequest()];

coerce 'RepeatedListGatewaySecurityPolicyRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesRequest'->new($_) } @$_ ] };

declare 'MapStringListGatewaySecurityPolicyRulesRequest',
    as HashRef[ListGatewaySecurityPolicyRulesRequest()];

declare 'ListGatewaySecurityPolicyRulesResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesResponse'];

coerce 'ListGatewaySecurityPolicyRulesResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesResponse'->new($_) };

declare 'RepeatedListGatewaySecurityPolicyRulesResponse',
    as ArrayRef[ListGatewaySecurityPolicyRulesResponse()];

coerce 'RepeatedListGatewaySecurityPolicyRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesResponse'->new($_) } @$_ ] };

declare 'MapStringListGatewaySecurityPolicyRulesResponse',
    as HashRef[ListGatewaySecurityPolicyRulesResponse()];

declare 'DeleteGatewaySecurityPolicyRuleRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::DeleteGatewaySecurityPolicyRuleRequest'];

coerce 'DeleteGatewaySecurityPolicyRuleRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::DeleteGatewaySecurityPolicyRuleRequest'->new($_) };

declare 'RepeatedDeleteGatewaySecurityPolicyRuleRequest',
    as ArrayRef[DeleteGatewaySecurityPolicyRuleRequest()];

coerce 'RepeatedDeleteGatewaySecurityPolicyRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::DeleteGatewaySecurityPolicyRuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGatewaySecurityPolicyRuleRequest',
    as HashRef[DeleteGatewaySecurityPolicyRuleRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
