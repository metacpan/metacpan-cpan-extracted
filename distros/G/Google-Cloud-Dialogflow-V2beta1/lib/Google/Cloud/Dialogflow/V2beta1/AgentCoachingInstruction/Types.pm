package Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AgentCoachingInstruction',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction'];

coerce 'AgentCoachingInstruction',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction'->new($_) };

declare 'RepeatedAgentCoachingInstruction',
    as ArrayRef[AgentCoachingInstruction()];

coerce 'RepeatedAgentCoachingInstruction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction'->new($_) } @$_ ] };

declare 'MapStringAgentCoachingInstruction',
    as HashRef[AgentCoachingInstruction()];

declare 'TriggerEvent',
    as (Int | Str);

declare 'DuplicateCheckResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction::DuplicateCheckResult'];

coerce 'DuplicateCheckResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction::DuplicateCheckResult'->new($_) };

declare 'RepeatedDuplicateCheckResult',
    as ArrayRef[DuplicateCheckResult()];

coerce 'RepeatedDuplicateCheckResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction::DuplicateCheckResult'->new($_) } @$_ ] };

declare 'MapStringDuplicateCheckResult',
    as HashRef[DuplicateCheckResult()];

declare 'DuplicateSuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction::DuplicateCheckResult::DuplicateSuggestion'];

coerce 'DuplicateSuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction::DuplicateCheckResult::DuplicateSuggestion'->new($_) };

declare 'RepeatedDuplicateSuggestion',
    as ArrayRef[DuplicateSuggestion()];

coerce 'RepeatedDuplicateSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction::DuplicateCheckResult::DuplicateSuggestion'->new($_) } @$_ ] };

declare 'MapStringDuplicateSuggestion',
    as HashRef[DuplicateSuggestion()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
