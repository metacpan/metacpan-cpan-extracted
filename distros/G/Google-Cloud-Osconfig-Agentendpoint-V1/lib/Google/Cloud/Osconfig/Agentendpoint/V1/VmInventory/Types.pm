package Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VmInventory',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::VmInventory'];

coerce 'VmInventory',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::VmInventory'->new($_) };

declare 'RepeatedVmInventory',
    as ArrayRef[VmInventory()];

coerce 'RepeatedVmInventory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::VmInventory'->new($_) } @$_ ] };

declare 'MapStringVmInventory',
    as HashRef[VmInventory()];

declare 'OsInfo',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::VmInventory::OsInfo'];

coerce 'OsInfo',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::VmInventory::OsInfo'->new($_) };

declare 'RepeatedOsInfo',
    as ArrayRef[OsInfo()];

coerce 'RepeatedOsInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::VmInventory::OsInfo'->new($_) } @$_ ] };

declare 'MapStringOsInfo',
    as HashRef[OsInfo()];

declare 'InventoryItem',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::VmInventory::InventoryItem'];

coerce 'InventoryItem',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::VmInventory::InventoryItem'->new($_) };

declare 'RepeatedInventoryItem',
    as ArrayRef[InventoryItem()];

coerce 'RepeatedInventoryItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::VmInventory::InventoryItem'->new($_) } @$_ ] };

declare 'MapStringInventoryItem',
    as HashRef[InventoryItem()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
