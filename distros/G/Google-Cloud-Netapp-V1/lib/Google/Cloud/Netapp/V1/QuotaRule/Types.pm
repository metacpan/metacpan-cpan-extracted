package Google::Cloud::Netapp::V1::QuotaRule::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListQuotaRulesRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesRequest'];

coerce 'ListQuotaRulesRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesRequest'->new($_) };

declare 'RepeatedListQuotaRulesRequest',
    as ArrayRef[ListQuotaRulesRequest()];

coerce 'RepeatedListQuotaRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesRequest'->new($_) } @$_ ] };

declare 'MapStringListQuotaRulesRequest',
    as HashRef[ListQuotaRulesRequest()];

declare 'ListQuotaRulesResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesResponse'];

coerce 'ListQuotaRulesResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesResponse'->new($_) };

declare 'RepeatedListQuotaRulesResponse',
    as ArrayRef[ListQuotaRulesResponse()];

coerce 'RepeatedListQuotaRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesResponse'->new($_) } @$_ ] };

declare 'MapStringListQuotaRulesResponse',
    as HashRef[ListQuotaRulesResponse()];

declare 'GetQuotaRuleRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::QuotaRule::GetQuotaRuleRequest'];

coerce 'GetQuotaRuleRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::QuotaRule::GetQuotaRuleRequest'->new($_) };

declare 'RepeatedGetQuotaRuleRequest',
    as ArrayRef[GetQuotaRuleRequest()];

coerce 'RepeatedGetQuotaRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::QuotaRule::GetQuotaRuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetQuotaRuleRequest',
    as HashRef[GetQuotaRuleRequest()];

declare 'CreateQuotaRuleRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::QuotaRule::CreateQuotaRuleRequest'];

coerce 'CreateQuotaRuleRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::QuotaRule::CreateQuotaRuleRequest'->new($_) };

declare 'RepeatedCreateQuotaRuleRequest',
    as ArrayRef[CreateQuotaRuleRequest()];

coerce 'RepeatedCreateQuotaRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::QuotaRule::CreateQuotaRuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateQuotaRuleRequest',
    as HashRef[CreateQuotaRuleRequest()];

declare 'UpdateQuotaRuleRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::QuotaRule::UpdateQuotaRuleRequest'];

coerce 'UpdateQuotaRuleRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::QuotaRule::UpdateQuotaRuleRequest'->new($_) };

declare 'RepeatedUpdateQuotaRuleRequest',
    as ArrayRef[UpdateQuotaRuleRequest()];

coerce 'RepeatedUpdateQuotaRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::QuotaRule::UpdateQuotaRuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateQuotaRuleRequest',
    as HashRef[UpdateQuotaRuleRequest()];

declare 'DeleteQuotaRuleRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::QuotaRule::DeleteQuotaRuleRequest'];

coerce 'DeleteQuotaRuleRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::QuotaRule::DeleteQuotaRuleRequest'->new($_) };

declare 'RepeatedDeleteQuotaRuleRequest',
    as ArrayRef[DeleteQuotaRuleRequest()];

coerce 'RepeatedDeleteQuotaRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::QuotaRule::DeleteQuotaRuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteQuotaRuleRequest',
    as HashRef[DeleteQuotaRuleRequest()];

declare 'QuotaRule',
    as InstanceOf['Google::Cloud::Netapp::V1::QuotaRule::QuotaRule'];

coerce 'QuotaRule',
    from HashRef, via { 'Google::Cloud::Netapp::V1::QuotaRule::QuotaRule'->new($_) };

declare 'RepeatedQuotaRule',
    as ArrayRef[QuotaRule()];

coerce 'RepeatedQuotaRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::QuotaRule::QuotaRule'->new($_) } @$_ ] };

declare 'MapStringQuotaRule',
    as HashRef[QuotaRule()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::QuotaRule::QuotaRule::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::QuotaRule::QuotaRule::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::QuotaRule::QuotaRule::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::QuotaRule::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
