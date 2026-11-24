package Google::Cloud::Deploy::V1::AutomationPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AutomationEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::AutomationPayload::AutomationEvent'];

coerce 'AutomationEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::AutomationPayload::AutomationEvent'->new($_) };

declare 'RepeatedAutomationEvent',
    as ArrayRef[AutomationEvent()];

coerce 'RepeatedAutomationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::AutomationPayload::AutomationEvent'->new($_) } @$_ ] };

declare 'MapStringAutomationEvent',
    as HashRef[AutomationEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::AutomationPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
