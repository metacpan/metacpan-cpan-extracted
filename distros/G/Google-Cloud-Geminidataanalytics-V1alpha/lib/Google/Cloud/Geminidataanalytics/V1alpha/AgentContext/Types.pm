package Google::Cloud::Geminidataanalytics::V1alpha::AgentContext::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AgentContextReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1alpha::AgentContext::AgentContextReference'];

coerce 'AgentContextReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1alpha::AgentContext::AgentContextReference'->new($_) };

declare 'RepeatedAgentContextReference',
    as ArrayRef[AgentContextReference()];

coerce 'RepeatedAgentContextReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1alpha::AgentContext::AgentContextReference'->new($_) } @$_ ] };

declare 'MapStringAgentContextReference',
    as HashRef[AgentContextReference()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1alpha::AgentContext::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
