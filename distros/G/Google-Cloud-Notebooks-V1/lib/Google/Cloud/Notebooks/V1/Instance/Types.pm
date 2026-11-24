package Google::Cloud::Notebooks::V1::Instance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReservationAffinity',
    as InstanceOf['Google::Cloud::Notebooks::V1::Instance::ReservationAffinity'];

coerce 'ReservationAffinity',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Instance::ReservationAffinity'->new($_) };

declare 'RepeatedReservationAffinity',
    as ArrayRef[ReservationAffinity()];

coerce 'RepeatedReservationAffinity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Instance::ReservationAffinity'->new($_) } @$_ ] };

declare 'MapStringReservationAffinity',
    as HashRef[ReservationAffinity()];

declare 'Type',
    as (Int | Str);

declare 'Instance',
    as InstanceOf['Google::Cloud::Notebooks::V1::Instance::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Instance::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Instance::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'AcceleratorType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'DiskType',
    as (Int | Str);

declare 'DiskEncryption',
    as (Int | Str);

declare 'NicType',
    as (Int | Str);

declare 'AcceleratorConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::Instance::Instance::AcceleratorConfig'];

coerce 'AcceleratorConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Instance::Instance::AcceleratorConfig'->new($_) };

declare 'RepeatedAcceleratorConfig',
    as ArrayRef[AcceleratorConfig()];

coerce 'RepeatedAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Instance::Instance::AcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringAcceleratorConfig',
    as HashRef[AcceleratorConfig()];

declare 'Disk',
    as InstanceOf['Google::Cloud::Notebooks::V1::Instance::Instance::Disk'];

coerce 'Disk',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Instance::Instance::Disk'->new($_) };

declare 'RepeatedDisk',
    as ArrayRef[Disk()];

coerce 'RepeatedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Instance::Instance::Disk'->new($_) } @$_ ] };

declare 'MapStringDisk',
    as HashRef[Disk()];

declare 'GuestOsFeature',
    as InstanceOf['Google::Cloud::Notebooks::V1::Instance::Instance::Disk::GuestOsFeature'];

coerce 'GuestOsFeature',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Instance::Instance::Disk::GuestOsFeature'->new($_) };

declare 'RepeatedGuestOsFeature',
    as ArrayRef[GuestOsFeature()];

coerce 'RepeatedGuestOsFeature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Instance::Instance::Disk::GuestOsFeature'->new($_) } @$_ ] };

declare 'MapStringGuestOsFeature',
    as HashRef[GuestOsFeature()];

declare 'ShieldedInstanceConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::Instance::Instance::ShieldedInstanceConfig'];

coerce 'ShieldedInstanceConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Instance::Instance::ShieldedInstanceConfig'->new($_) };

declare 'RepeatedShieldedInstanceConfig',
    as ArrayRef[ShieldedInstanceConfig()];

coerce 'RepeatedShieldedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Instance::Instance::ShieldedInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringShieldedInstanceConfig',
    as HashRef[ShieldedInstanceConfig()];

declare 'UpgradeHistoryEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Instance::Instance::UpgradeHistoryEntry'];

coerce 'UpgradeHistoryEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Instance::Instance::UpgradeHistoryEntry'->new($_) };

declare 'RepeatedUpgradeHistoryEntry',
    as ArrayRef[UpgradeHistoryEntry()];

coerce 'RepeatedUpgradeHistoryEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Instance::Instance::UpgradeHistoryEntry'->new($_) } @$_ ] };

declare 'MapStringUpgradeHistoryEntry',
    as HashRef[UpgradeHistoryEntry()];

declare 'State',
    as (Int | Str);

declare 'Action',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Instance::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Instance::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Instance::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Instance::Instance::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Instance::Instance::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Instance::Instance::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V1::Instance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
