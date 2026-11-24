package Google::Cloud::Securitycenter::V2::AgentSession::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AgentSession',
    as InstanceOf['Google::Cloud::Securitycenter::V2::AgentSession::AgentSession'];

coerce 'AgentSession',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::AgentSession::AgentSession'->new($_) };

declare 'RepeatedAgentSession',
    as ArrayRef[AgentSession()];

coerce 'RepeatedAgentSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::AgentSession::AgentSession'->new($_) } @$_ ] };

declare 'MapStringAgentSession',
    as HashRef[AgentSession()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::AgentSession::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
