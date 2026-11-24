package Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateRuleSetRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::CreateRuleSetRequest'];

coerce 'CreateRuleSetRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::CreateRuleSetRequest'->new($_) };

declare 'RepeatedCreateRuleSetRequest',
    as ArrayRef[CreateRuleSetRequest()];

coerce 'RepeatedCreateRuleSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::CreateRuleSetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRuleSetRequest',
    as HashRef[CreateRuleSetRequest()];

declare 'GetRuleSetRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::GetRuleSetRequest'];

coerce 'GetRuleSetRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::GetRuleSetRequest'->new($_) };

declare 'RepeatedGetRuleSetRequest',
    as ArrayRef[GetRuleSetRequest()];

coerce 'RepeatedGetRuleSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::GetRuleSetRequest'->new($_) } @$_ ] };

declare 'MapStringGetRuleSetRequest',
    as HashRef[GetRuleSetRequest()];

declare 'UpdateRuleSetRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::UpdateRuleSetRequest'];

coerce 'UpdateRuleSetRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::UpdateRuleSetRequest'->new($_) };

declare 'RepeatedUpdateRuleSetRequest',
    as ArrayRef[UpdateRuleSetRequest()];

coerce 'RepeatedUpdateRuleSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::UpdateRuleSetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRuleSetRequest',
    as HashRef[UpdateRuleSetRequest()];

declare 'DeleteRuleSetRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::DeleteRuleSetRequest'];

coerce 'DeleteRuleSetRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::DeleteRuleSetRequest'->new($_) };

declare 'RepeatedDeleteRuleSetRequest',
    as ArrayRef[DeleteRuleSetRequest()];

coerce 'RepeatedDeleteRuleSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::DeleteRuleSetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRuleSetRequest',
    as HashRef[DeleteRuleSetRequest()];

declare 'ListRuleSetsRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsRequest'];

coerce 'ListRuleSetsRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsRequest'->new($_) };

declare 'RepeatedListRuleSetsRequest',
    as ArrayRef[ListRuleSetsRequest()];

coerce 'RepeatedListRuleSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsRequest'->new($_) } @$_ ] };

declare 'MapStringListRuleSetsRequest',
    as HashRef[ListRuleSetsRequest()];

declare 'ListRuleSetsResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsResponse'];

coerce 'ListRuleSetsResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsResponse'->new($_) };

declare 'RepeatedListRuleSetsResponse',
    as ArrayRef[ListRuleSetsResponse()];

coerce 'RepeatedListRuleSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsResponse'->new($_) } @$_ ] };

declare 'MapStringListRuleSetsResponse',
    as HashRef[ListRuleSetsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
