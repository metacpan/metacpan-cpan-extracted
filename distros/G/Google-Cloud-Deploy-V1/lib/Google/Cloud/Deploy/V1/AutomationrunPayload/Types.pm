package Google::Cloud::Deploy::V1::AutomationrunPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AutomationRunEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::AutomationrunPayload::AutomationRunEvent'];

coerce 'AutomationRunEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::AutomationrunPayload::AutomationRunEvent'->new($_) };

declare 'RepeatedAutomationRunEvent',
    as ArrayRef[AutomationRunEvent()];

coerce 'RepeatedAutomationRunEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::AutomationrunPayload::AutomationRunEvent'->new($_) } @$_ ] };

declare 'MapStringAutomationRunEvent',
    as HashRef[AutomationRunEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::AutomationrunPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
