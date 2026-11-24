package Google::Cloud::Capacityplanner::V1beta::Allocation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Allocation',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation'];

coerce 'Allocation',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation'->new($_) };

declare 'RepeatedAllocation',
    as ArrayRef[Allocation()];

coerce 'RepeatedAllocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation'->new($_) } @$_ ] };

declare 'MapStringAllocation',
    as HashRef[Allocation()];

declare 'Status',
    as (Int | Str);

declare 'SpecificSKUAllocation',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation'];

coerce 'SpecificSKUAllocation',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation'->new($_) };

declare 'RepeatedSpecificSKUAllocation',
    as ArrayRef[SpecificSKUAllocation()];

coerce 'RepeatedSpecificSKUAllocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation'->new($_) } @$_ ] };

declare 'MapStringSpecificSKUAllocation',
    as HashRef[SpecificSKUAllocation()];

declare 'AllocatedInstanceProperties',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation::AllocatedInstanceProperties'];

coerce 'AllocatedInstanceProperties',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation::AllocatedInstanceProperties'->new($_) };

declare 'RepeatedAllocatedInstanceProperties',
    as ArrayRef[AllocatedInstanceProperties()];

coerce 'RepeatedAllocatedInstanceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation::AllocatedInstanceProperties'->new($_) } @$_ ] };

declare 'MapStringAllocatedInstanceProperties',
    as HashRef[AllocatedInstanceProperties()];

declare 'AcceleratorConfig',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation::AllocatedInstanceProperties::AcceleratorConfig'];

coerce 'AcceleratorConfig',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation::AllocatedInstanceProperties::AcceleratorConfig'->new($_) };

declare 'RepeatedAcceleratorConfig',
    as ArrayRef[AcceleratorConfig()];

coerce 'RepeatedAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation::AllocatedInstanceProperties::AcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringAcceleratorConfig',
    as HashRef[AcceleratorConfig()];

declare 'AllocatedDisk',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation::AllocatedInstanceProperties::AllocatedDisk'];

coerce 'AllocatedDisk',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation::AllocatedInstanceProperties::AllocatedDisk'->new($_) };

declare 'RepeatedAllocatedDisk',
    as ArrayRef[AllocatedDisk()];

coerce 'RepeatedAllocatedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::SpecificSKUAllocation::AllocatedInstanceProperties::AllocatedDisk'->new($_) } @$_ ] };

declare 'MapStringAllocatedDisk',
    as HashRef[AllocatedDisk()];

declare 'DiskInterface',
    as (Int | Str);

declare 'ShareSettings',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::ShareSettings'];

coerce 'ShareSettings',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::ShareSettings'->new($_) };

declare 'RepeatedShareSettings',
    as ArrayRef[ShareSettings()];

coerce 'RepeatedShareSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Allocation::Allocation::ShareSettings'->new($_) } @$_ ] };

declare 'MapStringShareSettings',
    as HashRef[ShareSettings()];

declare 'ShareType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Capacityplanner::V1beta::Allocation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
