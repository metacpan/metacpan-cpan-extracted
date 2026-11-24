package Google::Cloud::Chronicle::V1::Rule::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RunFrequency',
    as (Int | Str);

declare 'RuleType',
    as (Int | Str);

declare 'RuleView',
    as (Int | Str);

declare 'Rule',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::Rule'];

coerce 'Rule',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::Rule'->new($_) };

declare 'RepeatedRule',
    as ArrayRef[Rule()];

coerce 'RepeatedRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::Rule'->new($_) } @$_ ] };

declare 'MapStringRule',
    as HashRef[Rule()];

declare 'CompilationState',
    as (Int | Str);

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::Rule::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::Rule::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::Rule::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'RuleDeployment',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::RuleDeployment'];

coerce 'RuleDeployment',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::RuleDeployment'->new($_) };

declare 'RepeatedRuleDeployment',
    as ArrayRef[RuleDeployment()];

coerce 'RepeatedRuleDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::RuleDeployment'->new($_) } @$_ ] };

declare 'MapStringRuleDeployment',
    as HashRef[RuleDeployment()];

declare 'ExecutionState',
    as (Int | Str);

declare 'Retrohunt',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::Retrohunt'];

coerce 'Retrohunt',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::Retrohunt'->new($_) };

declare 'RepeatedRetrohunt',
    as ArrayRef[Retrohunt()];

coerce 'RepeatedRetrohunt',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::Retrohunt'->new($_) } @$_ ] };

declare 'MapStringRetrohunt',
    as HashRef[Retrohunt()];

declare 'State',
    as (Int | Str);

declare 'CreateRuleRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::CreateRuleRequest'];

coerce 'CreateRuleRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::CreateRuleRequest'->new($_) };

declare 'RepeatedCreateRuleRequest',
    as ArrayRef[CreateRuleRequest()];

coerce 'RepeatedCreateRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::CreateRuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRuleRequest',
    as HashRef[CreateRuleRequest()];

declare 'GetRuleRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::GetRuleRequest'];

coerce 'GetRuleRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::GetRuleRequest'->new($_) };

declare 'RepeatedGetRuleRequest',
    as ArrayRef[GetRuleRequest()];

coerce 'RepeatedGetRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::GetRuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetRuleRequest',
    as HashRef[GetRuleRequest()];

declare 'ListRulesRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::ListRulesRequest'];

coerce 'ListRulesRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::ListRulesRequest'->new($_) };

declare 'RepeatedListRulesRequest',
    as ArrayRef[ListRulesRequest()];

coerce 'RepeatedListRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::ListRulesRequest'->new($_) } @$_ ] };

declare 'MapStringListRulesRequest',
    as HashRef[ListRulesRequest()];

declare 'ListRulesResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::ListRulesResponse'];

coerce 'ListRulesResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::ListRulesResponse'->new($_) };

declare 'RepeatedListRulesResponse',
    as ArrayRef[ListRulesResponse()];

coerce 'RepeatedListRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::ListRulesResponse'->new($_) } @$_ ] };

declare 'MapStringListRulesResponse',
    as HashRef[ListRulesResponse()];

declare 'UpdateRuleRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::UpdateRuleRequest'];

coerce 'UpdateRuleRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::UpdateRuleRequest'->new($_) };

declare 'RepeatedUpdateRuleRequest',
    as ArrayRef[UpdateRuleRequest()];

coerce 'RepeatedUpdateRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::UpdateRuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRuleRequest',
    as HashRef[UpdateRuleRequest()];

declare 'DeleteRuleRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::DeleteRuleRequest'];

coerce 'DeleteRuleRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::DeleteRuleRequest'->new($_) };

declare 'RepeatedDeleteRuleRequest',
    as ArrayRef[DeleteRuleRequest()];

coerce 'RepeatedDeleteRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::DeleteRuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRuleRequest',
    as HashRef[DeleteRuleRequest()];

declare 'VerifyRuleTextRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::VerifyRuleTextRequest'];

coerce 'VerifyRuleTextRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::VerifyRuleTextRequest'->new($_) };

declare 'RepeatedVerifyRuleTextRequest',
    as ArrayRef[VerifyRuleTextRequest()];

coerce 'RepeatedVerifyRuleTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::VerifyRuleTextRequest'->new($_) } @$_ ] };

declare 'MapStringVerifyRuleTextRequest',
    as HashRef[VerifyRuleTextRequest()];

declare 'VerifyRuleTextResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::VerifyRuleTextResponse'];

coerce 'VerifyRuleTextResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::VerifyRuleTextResponse'->new($_) };

declare 'RepeatedVerifyRuleTextResponse',
    as ArrayRef[VerifyRuleTextResponse()];

coerce 'RepeatedVerifyRuleTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::VerifyRuleTextResponse'->new($_) } @$_ ] };

declare 'MapStringVerifyRuleTextResponse',
    as HashRef[VerifyRuleTextResponse()];

declare 'ListRuleRevisionsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::ListRuleRevisionsRequest'];

coerce 'ListRuleRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::ListRuleRevisionsRequest'->new($_) };

declare 'RepeatedListRuleRevisionsRequest',
    as ArrayRef[ListRuleRevisionsRequest()];

coerce 'RepeatedListRuleRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::ListRuleRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListRuleRevisionsRequest',
    as HashRef[ListRuleRevisionsRequest()];

declare 'ListRuleRevisionsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::ListRuleRevisionsResponse'];

coerce 'ListRuleRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::ListRuleRevisionsResponse'->new($_) };

declare 'RepeatedListRuleRevisionsResponse',
    as ArrayRef[ListRuleRevisionsResponse()];

coerce 'RepeatedListRuleRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::ListRuleRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListRuleRevisionsResponse',
    as HashRef[ListRuleRevisionsResponse()];

declare 'CreateRetrohuntRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::CreateRetrohuntRequest'];

coerce 'CreateRetrohuntRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::CreateRetrohuntRequest'->new($_) };

declare 'RepeatedCreateRetrohuntRequest',
    as ArrayRef[CreateRetrohuntRequest()];

coerce 'RepeatedCreateRetrohuntRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::CreateRetrohuntRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRetrohuntRequest',
    as HashRef[CreateRetrohuntRequest()];

declare 'GetRetrohuntRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::GetRetrohuntRequest'];

coerce 'GetRetrohuntRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::GetRetrohuntRequest'->new($_) };

declare 'RepeatedGetRetrohuntRequest',
    as ArrayRef[GetRetrohuntRequest()];

coerce 'RepeatedGetRetrohuntRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::GetRetrohuntRequest'->new($_) } @$_ ] };

declare 'MapStringGetRetrohuntRequest',
    as HashRef[GetRetrohuntRequest()];

declare 'ListRetrohuntsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::ListRetrohuntsRequest'];

coerce 'ListRetrohuntsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::ListRetrohuntsRequest'->new($_) };

declare 'RepeatedListRetrohuntsRequest',
    as ArrayRef[ListRetrohuntsRequest()];

coerce 'RepeatedListRetrohuntsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::ListRetrohuntsRequest'->new($_) } @$_ ] };

declare 'MapStringListRetrohuntsRequest',
    as HashRef[ListRetrohuntsRequest()];

declare 'ListRetrohuntsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::ListRetrohuntsResponse'];

coerce 'ListRetrohuntsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::ListRetrohuntsResponse'->new($_) };

declare 'RepeatedListRetrohuntsResponse',
    as ArrayRef[ListRetrohuntsResponse()];

coerce 'RepeatedListRetrohuntsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::ListRetrohuntsResponse'->new($_) } @$_ ] };

declare 'MapStringListRetrohuntsResponse',
    as HashRef[ListRetrohuntsResponse()];

declare 'GetRuleDeploymentRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::GetRuleDeploymentRequest'];

coerce 'GetRuleDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::GetRuleDeploymentRequest'->new($_) };

declare 'RepeatedGetRuleDeploymentRequest',
    as ArrayRef[GetRuleDeploymentRequest()];

coerce 'RepeatedGetRuleDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::GetRuleDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetRuleDeploymentRequest',
    as HashRef[GetRuleDeploymentRequest()];

declare 'ListRuleDeploymentsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::ListRuleDeploymentsRequest'];

coerce 'ListRuleDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::ListRuleDeploymentsRequest'->new($_) };

declare 'RepeatedListRuleDeploymentsRequest',
    as ArrayRef[ListRuleDeploymentsRequest()];

coerce 'RepeatedListRuleDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::ListRuleDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListRuleDeploymentsRequest',
    as HashRef[ListRuleDeploymentsRequest()];

declare 'ListRuleDeploymentsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::ListRuleDeploymentsResponse'];

coerce 'ListRuleDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::ListRuleDeploymentsResponse'->new($_) };

declare 'RepeatedListRuleDeploymentsResponse',
    as ArrayRef[ListRuleDeploymentsResponse()];

coerce 'RepeatedListRuleDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::ListRuleDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListRuleDeploymentsResponse',
    as HashRef[ListRuleDeploymentsResponse()];

declare 'UpdateRuleDeploymentRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::UpdateRuleDeploymentRequest'];

coerce 'UpdateRuleDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::UpdateRuleDeploymentRequest'->new($_) };

declare 'RepeatedUpdateRuleDeploymentRequest',
    as ArrayRef[UpdateRuleDeploymentRequest()];

coerce 'RepeatedUpdateRuleDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::UpdateRuleDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRuleDeploymentRequest',
    as HashRef[UpdateRuleDeploymentRequest()];

declare 'CompilationPosition',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::CompilationPosition'];

coerce 'CompilationPosition',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::CompilationPosition'->new($_) };

declare 'RepeatedCompilationPosition',
    as ArrayRef[CompilationPosition()];

coerce 'RepeatedCompilationPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::CompilationPosition'->new($_) } @$_ ] };

declare 'MapStringCompilationPosition',
    as HashRef[CompilationPosition()];

declare 'CompilationDiagnostic',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::CompilationDiagnostic'];

coerce 'CompilationDiagnostic',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::CompilationDiagnostic'->new($_) };

declare 'RepeatedCompilationDiagnostic',
    as ArrayRef[CompilationDiagnostic()];

coerce 'RepeatedCompilationDiagnostic',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::CompilationDiagnostic'->new($_) } @$_ ] };

declare 'MapStringCompilationDiagnostic',
    as HashRef[CompilationDiagnostic()];

declare 'Severity',
    as (Int | Str);

declare 'Severity',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::Severity'];

coerce 'Severity',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::Severity'->new($_) };

declare 'RepeatedSeverity',
    as ArrayRef[Severity()];

coerce 'RepeatedSeverity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::Severity'->new($_) } @$_ ] };

declare 'MapStringSeverity',
    as HashRef[Severity()];

declare 'RetrohuntMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::RetrohuntMetadata'];

coerce 'RetrohuntMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::RetrohuntMetadata'->new($_) };

declare 'RepeatedRetrohuntMetadata',
    as ArrayRef[RetrohuntMetadata()];

coerce 'RepeatedRetrohuntMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::RetrohuntMetadata'->new($_) } @$_ ] };

declare 'MapStringRetrohuntMetadata',
    as HashRef[RetrohuntMetadata()];

declare 'InputsUsed',
    as InstanceOf['Google::Cloud::Chronicle::V1::Rule::InputsUsed'];

coerce 'InputsUsed',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Rule::InputsUsed'->new($_) };

declare 'RepeatedInputsUsed',
    as ArrayRef[InputsUsed()];

coerce 'RepeatedInputsUsed',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Rule::InputsUsed'->new($_) } @$_ ] };

declare 'MapStringInputsUsed',
    as HashRef[InputsUsed()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::Rule::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
