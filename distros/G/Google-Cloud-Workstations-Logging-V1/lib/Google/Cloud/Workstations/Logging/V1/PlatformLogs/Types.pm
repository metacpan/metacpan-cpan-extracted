package Google::Cloud::Workstations::Logging::V1::PlatformLogs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WorkstationEvent',
    as InstanceOf['Google::Cloud::Workstations::Logging::V1::PlatformLogs::WorkstationEvent'];

coerce 'WorkstationEvent',
    from HashRef, via { 'Google::Cloud::Workstations::Logging::V1::PlatformLogs::WorkstationEvent'->new($_) };

declare 'RepeatedWorkstationEvent',
    as ArrayRef[WorkstationEvent()];

coerce 'RepeatedWorkstationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::Logging::V1::PlatformLogs::WorkstationEvent'->new($_) } @$_ ] };

declare 'MapStringWorkstationEvent',
    as HashRef[WorkstationEvent()];

declare 'VmAssignmentEvent',
    as InstanceOf['Google::Cloud::Workstations::Logging::V1::PlatformLogs::VmAssignmentEvent'];

coerce 'VmAssignmentEvent',
    from HashRef, via { 'Google::Cloud::Workstations::Logging::V1::PlatformLogs::VmAssignmentEvent'->new($_) };

declare 'RepeatedVmAssignmentEvent',
    as ArrayRef[VmAssignmentEvent()];

coerce 'RepeatedVmAssignmentEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::Logging::V1::PlatformLogs::VmAssignmentEvent'->new($_) } @$_ ] };

declare 'MapStringVmAssignmentEvent',
    as HashRef[VmAssignmentEvent()];

declare 'DiskAssignmentEvent',
    as InstanceOf['Google::Cloud::Workstations::Logging::V1::PlatformLogs::DiskAssignmentEvent'];

coerce 'DiskAssignmentEvent',
    from HashRef, via { 'Google::Cloud::Workstations::Logging::V1::PlatformLogs::DiskAssignmentEvent'->new($_) };

declare 'RepeatedDiskAssignmentEvent',
    as ArrayRef[DiskAssignmentEvent()];

coerce 'RepeatedDiskAssignmentEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::Logging::V1::PlatformLogs::DiskAssignmentEvent'->new($_) } @$_ ] };

declare 'MapStringDiskAssignmentEvent',
    as HashRef[DiskAssignmentEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Workstations::Logging::V1::PlatformLogs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
