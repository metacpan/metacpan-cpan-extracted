package Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Inventory',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory'];

coerce 'Inventory',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory'->new($_) };

declare 'RepeatedInventory',
    as ArrayRef[Inventory()];

coerce 'RepeatedInventory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory'->new($_) } @$_ ] };

declare 'MapStringInventory',
    as HashRef[Inventory()];

declare 'OsInfo',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::OsInfo'];

coerce 'OsInfo',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::OsInfo'->new($_) };

declare 'RepeatedOsInfo',
    as ArrayRef[OsInfo()];

coerce 'RepeatedOsInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::OsInfo'->new($_) } @$_ ] };

declare 'MapStringOsInfo',
    as HashRef[OsInfo()];

declare 'SoftwarePackage',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::SoftwarePackage'];

coerce 'SoftwarePackage',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::SoftwarePackage'->new($_) };

declare 'RepeatedSoftwarePackage',
    as ArrayRef[SoftwarePackage()];

coerce 'RepeatedSoftwarePackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::SoftwarePackage'->new($_) } @$_ ] };

declare 'MapStringSoftwarePackage',
    as HashRef[SoftwarePackage()];

declare 'VersionedPackage',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::VersionedPackage'];

coerce 'VersionedPackage',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::VersionedPackage'->new($_) };

declare 'RepeatedVersionedPackage',
    as ArrayRef[VersionedPackage()];

coerce 'RepeatedVersionedPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::VersionedPackage'->new($_) } @$_ ] };

declare 'MapStringVersionedPackage',
    as HashRef[VersionedPackage()];

declare 'Source',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::VersionedPackage::Source'];

coerce 'Source',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::VersionedPackage::Source'->new($_) };

declare 'RepeatedSource',
    as ArrayRef[Source()];

coerce 'RepeatedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::VersionedPackage::Source'->new($_) } @$_ ] };

declare 'MapStringSource',
    as HashRef[Source()];

declare 'ZypperPatch',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::ZypperPatch'];

coerce 'ZypperPatch',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::ZypperPatch'->new($_) };

declare 'RepeatedZypperPatch',
    as ArrayRef[ZypperPatch()];

coerce 'RepeatedZypperPatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::ZypperPatch'->new($_) } @$_ ] };

declare 'MapStringZypperPatch',
    as HashRef[ZypperPatch()];

declare 'WindowsUpdatePackage',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsUpdatePackage'];

coerce 'WindowsUpdatePackage',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsUpdatePackage'->new($_) };

declare 'RepeatedWindowsUpdatePackage',
    as ArrayRef[WindowsUpdatePackage()];

coerce 'RepeatedWindowsUpdatePackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsUpdatePackage'->new($_) } @$_ ] };

declare 'MapStringWindowsUpdatePackage',
    as HashRef[WindowsUpdatePackage()];

declare 'WindowsUpdateCategory',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsUpdatePackage::WindowsUpdateCategory'];

coerce 'WindowsUpdateCategory',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsUpdatePackage::WindowsUpdateCategory'->new($_) };

declare 'RepeatedWindowsUpdateCategory',
    as ArrayRef[WindowsUpdateCategory()];

coerce 'RepeatedWindowsUpdateCategory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsUpdatePackage::WindowsUpdateCategory'->new($_) } @$_ ] };

declare 'MapStringWindowsUpdateCategory',
    as HashRef[WindowsUpdateCategory()];

declare 'WindowsQuickFixEngineeringPackage',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsQuickFixEngineeringPackage'];

coerce 'WindowsQuickFixEngineeringPackage',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsQuickFixEngineeringPackage'->new($_) };

declare 'RepeatedWindowsQuickFixEngineeringPackage',
    as ArrayRef[WindowsQuickFixEngineeringPackage()];

coerce 'RepeatedWindowsQuickFixEngineeringPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsQuickFixEngineeringPackage'->new($_) } @$_ ] };

declare 'MapStringWindowsQuickFixEngineeringPackage',
    as HashRef[WindowsQuickFixEngineeringPackage()];

declare 'WindowsApplication',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsApplication'];

coerce 'WindowsApplication',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsApplication'->new($_) };

declare 'RepeatedWindowsApplication',
    as ArrayRef[WindowsApplication()];

coerce 'RepeatedWindowsApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory::WindowsApplication'->new($_) } @$_ ] };

declare 'MapStringWindowsApplication',
    as HashRef[WindowsApplication()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
