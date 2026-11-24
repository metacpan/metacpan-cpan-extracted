package Google::Cloud::Baremetalsolution::V2::Volume::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Volume',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Volume::Volume'];

coerce 'Volume',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Volume::Volume'->new($_) };

declare 'RepeatedVolume',
    as ArrayRef[Volume()];

coerce 'RepeatedVolume',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Volume::Volume'->new($_) } @$_ ] };

declare 'MapStringVolume',
    as HashRef[Volume()];

declare 'StorageType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'SnapshotAutoDeleteBehavior',
    as (Int | Str);

declare 'Protocol',
    as (Int | Str);

declare 'WorkloadProfile',
    as (Int | Str);

declare 'SnapshotReservationDetail',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Volume::Volume::SnapshotReservationDetail'];

coerce 'SnapshotReservationDetail',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Volume::Volume::SnapshotReservationDetail'->new($_) };

declare 'RepeatedSnapshotReservationDetail',
    as ArrayRef[SnapshotReservationDetail()];

coerce 'RepeatedSnapshotReservationDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Volume::Volume::SnapshotReservationDetail'->new($_) } @$_ ] };

declare 'MapStringSnapshotReservationDetail',
    as HashRef[SnapshotReservationDetail()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Volume::Volume::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Volume::Volume::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Volume::Volume::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetVolumeRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Volume::GetVolumeRequest'];

coerce 'GetVolumeRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Volume::GetVolumeRequest'->new($_) };

declare 'RepeatedGetVolumeRequest',
    as ArrayRef[GetVolumeRequest()];

coerce 'RepeatedGetVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Volume::GetVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringGetVolumeRequest',
    as HashRef[GetVolumeRequest()];

declare 'ListVolumesRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Volume::ListVolumesRequest'];

coerce 'ListVolumesRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Volume::ListVolumesRequest'->new($_) };

declare 'RepeatedListVolumesRequest',
    as ArrayRef[ListVolumesRequest()];

coerce 'RepeatedListVolumesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Volume::ListVolumesRequest'->new($_) } @$_ ] };

declare 'MapStringListVolumesRequest',
    as HashRef[ListVolumesRequest()];

declare 'ListVolumesResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Volume::ListVolumesResponse'];

coerce 'ListVolumesResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Volume::ListVolumesResponse'->new($_) };

declare 'RepeatedListVolumesResponse',
    as ArrayRef[ListVolumesResponse()];

coerce 'RepeatedListVolumesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Volume::ListVolumesResponse'->new($_) } @$_ ] };

declare 'MapStringListVolumesResponse',
    as HashRef[ListVolumesResponse()];

declare 'UpdateVolumeRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Volume::UpdateVolumeRequest'];

coerce 'UpdateVolumeRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Volume::UpdateVolumeRequest'->new($_) };

declare 'RepeatedUpdateVolumeRequest',
    as ArrayRef[UpdateVolumeRequest()];

coerce 'RepeatedUpdateVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Volume::UpdateVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVolumeRequest',
    as HashRef[UpdateVolumeRequest()];

declare 'RenameVolumeRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Volume::RenameVolumeRequest'];

coerce 'RenameVolumeRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Volume::RenameVolumeRequest'->new($_) };

declare 'RepeatedRenameVolumeRequest',
    as ArrayRef[RenameVolumeRequest()];

coerce 'RepeatedRenameVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Volume::RenameVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringRenameVolumeRequest',
    as HashRef[RenameVolumeRequest()];

declare 'EvictVolumeRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Volume::EvictVolumeRequest'];

coerce 'EvictVolumeRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Volume::EvictVolumeRequest'->new($_) };

declare 'RepeatedEvictVolumeRequest',
    as ArrayRef[EvictVolumeRequest()];

coerce 'RepeatedEvictVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Volume::EvictVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringEvictVolumeRequest',
    as HashRef[EvictVolumeRequest()];

declare 'ResizeVolumeRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Volume::ResizeVolumeRequest'];

coerce 'ResizeVolumeRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Volume::ResizeVolumeRequest'->new($_) };

declare 'RepeatedResizeVolumeRequest',
    as ArrayRef[ResizeVolumeRequest()];

coerce 'RepeatedResizeVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Volume::ResizeVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringResizeVolumeRequest',
    as HashRef[ResizeVolumeRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Volume::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
