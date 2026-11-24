package Google::Cloud::Securitycenter::V1::ExternalSystem::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExternalSystem',
    as InstanceOf['Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem'];

coerce 'ExternalSystem',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem'->new($_) };

declare 'RepeatedExternalSystem',
    as ArrayRef[ExternalSystem()];

coerce 'RepeatedExternalSystem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem'->new($_) } @$_ ] };

declare 'MapStringExternalSystem',
    as HashRef[ExternalSystem()];

declare 'TicketInfo',
    as InstanceOf['Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem::TicketInfo'];

coerce 'TicketInfo',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem::TicketInfo'->new($_) };

declare 'RepeatedTicketInfo',
    as ArrayRef[TicketInfo()];

coerce 'RepeatedTicketInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem::TicketInfo'->new($_) } @$_ ] };

declare 'MapStringTicketInfo',
    as HashRef[TicketInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::ExternalSystem::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
