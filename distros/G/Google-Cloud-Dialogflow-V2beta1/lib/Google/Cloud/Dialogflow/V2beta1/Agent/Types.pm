package Google::Cloud::Dialogflow::V2beta1::Agent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Agent',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::Agent'];

coerce 'Agent',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::Agent'->new($_) };

declare 'RepeatedAgent',
    as ArrayRef[Agent()];

coerce 'RepeatedAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::Agent'->new($_) } @$_ ] };

declare 'MapStringAgent',
    as HashRef[Agent()];

declare 'MatchMode',
    as (Int | Str);

declare 'ApiVersion',
    as (Int | Str);

declare 'Tier',
    as (Int | Str);

declare 'GetAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::GetAgentRequest'];

coerce 'GetAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::GetAgentRequest'->new($_) };

declare 'RepeatedGetAgentRequest',
    as ArrayRef[GetAgentRequest()];

coerce 'RepeatedGetAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::GetAgentRequest'->new($_) } @$_ ] };

declare 'MapStringGetAgentRequest',
    as HashRef[GetAgentRequest()];

declare 'SetAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::SetAgentRequest'];

coerce 'SetAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::SetAgentRequest'->new($_) };

declare 'RepeatedSetAgentRequest',
    as ArrayRef[SetAgentRequest()];

coerce 'RepeatedSetAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::SetAgentRequest'->new($_) } @$_ ] };

declare 'MapStringSetAgentRequest',
    as HashRef[SetAgentRequest()];

declare 'DeleteAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::DeleteAgentRequest'];

coerce 'DeleteAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::DeleteAgentRequest'->new($_) };

declare 'RepeatedDeleteAgentRequest',
    as ArrayRef[DeleteAgentRequest()];

coerce 'RepeatedDeleteAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::DeleteAgentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAgentRequest',
    as HashRef[DeleteAgentRequest()];

declare 'SubAgent',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::SubAgent'];

coerce 'SubAgent',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::SubAgent'->new($_) };

declare 'RepeatedSubAgent',
    as ArrayRef[SubAgent()];

coerce 'RepeatedSubAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::SubAgent'->new($_) } @$_ ] };

declare 'MapStringSubAgent',
    as HashRef[SubAgent()];

declare 'SearchAgentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::SearchAgentsRequest'];

coerce 'SearchAgentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::SearchAgentsRequest'->new($_) };

declare 'RepeatedSearchAgentsRequest',
    as ArrayRef[SearchAgentsRequest()];

coerce 'RepeatedSearchAgentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::SearchAgentsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchAgentsRequest',
    as HashRef[SearchAgentsRequest()];

declare 'SearchAgentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::SearchAgentsResponse'];

coerce 'SearchAgentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::SearchAgentsResponse'->new($_) };

declare 'RepeatedSearchAgentsResponse',
    as ArrayRef[SearchAgentsResponse()];

coerce 'RepeatedSearchAgentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::SearchAgentsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchAgentsResponse',
    as HashRef[SearchAgentsResponse()];

declare 'TrainAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::TrainAgentRequest'];

coerce 'TrainAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::TrainAgentRequest'->new($_) };

declare 'RepeatedTrainAgentRequest',
    as ArrayRef[TrainAgentRequest()];

coerce 'RepeatedTrainAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::TrainAgentRequest'->new($_) } @$_ ] };

declare 'MapStringTrainAgentRequest',
    as HashRef[TrainAgentRequest()];

declare 'ExportAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::ExportAgentRequest'];

coerce 'ExportAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::ExportAgentRequest'->new($_) };

declare 'RepeatedExportAgentRequest',
    as ArrayRef[ExportAgentRequest()];

coerce 'RepeatedExportAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::ExportAgentRequest'->new($_) } @$_ ] };

declare 'MapStringExportAgentRequest',
    as HashRef[ExportAgentRequest()];

declare 'ExportAgentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::ExportAgentResponse'];

coerce 'ExportAgentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::ExportAgentResponse'->new($_) };

declare 'RepeatedExportAgentResponse',
    as ArrayRef[ExportAgentResponse()];

coerce 'RepeatedExportAgentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::ExportAgentResponse'->new($_) } @$_ ] };

declare 'MapStringExportAgentResponse',
    as HashRef[ExportAgentResponse()];

declare 'ImportAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::ImportAgentRequest'];

coerce 'ImportAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::ImportAgentRequest'->new($_) };

declare 'RepeatedImportAgentRequest',
    as ArrayRef[ImportAgentRequest()];

coerce 'RepeatedImportAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::ImportAgentRequest'->new($_) } @$_ ] };

declare 'MapStringImportAgentRequest',
    as HashRef[ImportAgentRequest()];

declare 'RestoreAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::RestoreAgentRequest'];

coerce 'RestoreAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::RestoreAgentRequest'->new($_) };

declare 'RepeatedRestoreAgentRequest',
    as ArrayRef[RestoreAgentRequest()];

coerce 'RepeatedRestoreAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::RestoreAgentRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreAgentRequest',
    as HashRef[RestoreAgentRequest()];

declare 'GetValidationResultRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Agent::GetValidationResultRequest'];

coerce 'GetValidationResultRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Agent::GetValidationResultRequest'->new($_) };

declare 'RepeatedGetValidationResultRequest',
    as ArrayRef[GetValidationResultRequest()];

coerce 'RepeatedGetValidationResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Agent::GetValidationResultRequest'->new($_) } @$_ ] };

declare 'MapStringGetValidationResultRequest',
    as HashRef[GetValidationResultRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Agent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
