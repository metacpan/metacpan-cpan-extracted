package Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HumanAgentAssistantEvent',
    as InstanceOf['Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent::HumanAgentAssistantEvent'];

coerce 'HumanAgentAssistantEvent',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent::HumanAgentAssistantEvent'->new($_) };

declare 'RepeatedHumanAgentAssistantEvent',
    as ArrayRef[HumanAgentAssistantEvent()];

coerce 'RepeatedHumanAgentAssistantEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent::HumanAgentAssistantEvent'->new($_) } @$_ ] };

declare 'MapStringHumanAgentAssistantEvent',
    as HashRef[HumanAgentAssistantEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
