package Google::Cloud::Ces::V1beta::AgentTool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AgentTool',
    as InstanceOf['Google::Cloud::Ces::V1beta::AgentTool::AgentTool'];

coerce 'AgentTool',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AgentTool::AgentTool'->new($_) };

declare 'RepeatedAgentTool',
    as ArrayRef[AgentTool()];

coerce 'RepeatedAgentTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AgentTool::AgentTool'->new($_) } @$_ ] };

declare 'MapStringAgentTool',
    as HashRef[AgentTool()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::AgentTool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
