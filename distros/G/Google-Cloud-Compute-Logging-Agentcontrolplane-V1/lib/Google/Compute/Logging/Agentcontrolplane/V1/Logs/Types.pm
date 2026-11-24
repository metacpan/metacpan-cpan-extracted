package Google::Compute::Logging::Agentcontrolplane::V1::Logs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VmExtensionEvent',
    as InstanceOf['Google::Compute::Logging::Agentcontrolplane::V1::Logs::VmExtensionEvent'];

coerce 'VmExtensionEvent',
    from HashRef, via { 'Google::Compute::Logging::Agentcontrolplane::V1::Logs::VmExtensionEvent'->new($_) };

declare 'RepeatedVmExtensionEvent',
    as ArrayRef[VmExtensionEvent()];

coerce 'RepeatedVmExtensionEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Compute::Logging::Agentcontrolplane::V1::Logs::VmExtensionEvent'->new($_) } @$_ ] };

declare 'MapStringVmExtensionEvent',
    as HashRef[VmExtensionEvent()];

declare 'ExtensionEventType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Compute::Logging::Agentcontrolplane::V1::Logs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
