package Google::Devtools::Artifactregistry::V1::Rule::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Rule',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Rule::Rule'];

coerce 'Rule',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Rule::Rule'->new($_) };

declare 'RepeatedRule',
    as ArrayRef[Rule()];

coerce 'RepeatedRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Rule::Rule'->new($_) } @$_ ] };

declare 'MapStringRule',
    as HashRef[Rule()];

declare 'Action',
    as (Int | Str);

declare 'Operation',
    as (Int | Str);

declare 'ListRulesRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Rule::ListRulesRequest'];

coerce 'ListRulesRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Rule::ListRulesRequest'->new($_) };

declare 'RepeatedListRulesRequest',
    as ArrayRef[ListRulesRequest()];

coerce 'RepeatedListRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Rule::ListRulesRequest'->new($_) } @$_ ] };

declare 'MapStringListRulesRequest',
    as HashRef[ListRulesRequest()];

declare 'ListRulesResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Rule::ListRulesResponse'];

coerce 'ListRulesResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Rule::ListRulesResponse'->new($_) };

declare 'RepeatedListRulesResponse',
    as ArrayRef[ListRulesResponse()];

coerce 'RepeatedListRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Rule::ListRulesResponse'->new($_) } @$_ ] };

declare 'MapStringListRulesResponse',
    as HashRef[ListRulesResponse()];

declare 'GetRuleRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Rule::GetRuleRequest'];

coerce 'GetRuleRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Rule::GetRuleRequest'->new($_) };

declare 'RepeatedGetRuleRequest',
    as ArrayRef[GetRuleRequest()];

coerce 'RepeatedGetRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Rule::GetRuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetRuleRequest',
    as HashRef[GetRuleRequest()];

declare 'CreateRuleRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Rule::CreateRuleRequest'];

coerce 'CreateRuleRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Rule::CreateRuleRequest'->new($_) };

declare 'RepeatedCreateRuleRequest',
    as ArrayRef[CreateRuleRequest()];

coerce 'RepeatedCreateRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Rule::CreateRuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRuleRequest',
    as HashRef[CreateRuleRequest()];

declare 'UpdateRuleRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Rule::UpdateRuleRequest'];

coerce 'UpdateRuleRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Rule::UpdateRuleRequest'->new($_) };

declare 'RepeatedUpdateRuleRequest',
    as ArrayRef[UpdateRuleRequest()];

coerce 'RepeatedUpdateRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Rule::UpdateRuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRuleRequest',
    as HashRef[UpdateRuleRequest()];

declare 'DeleteRuleRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Rule::DeleteRuleRequest'];

coerce 'DeleteRuleRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Rule::DeleteRuleRequest'->new($_) };

declare 'RepeatedDeleteRuleRequest',
    as ArrayRef[DeleteRuleRequest()];

coerce 'RepeatedDeleteRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Rule::DeleteRuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRuleRequest',
    as HashRef[DeleteRuleRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::Rule::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
