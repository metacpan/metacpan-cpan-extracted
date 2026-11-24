package Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VolumeSnapshot',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::VolumeSnapshot'];

coerce 'VolumeSnapshot',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::VolumeSnapshot'->new($_) };

declare 'RepeatedVolumeSnapshot',
    as ArrayRef[VolumeSnapshot()];

coerce 'RepeatedVolumeSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::VolumeSnapshot'->new($_) } @$_ ] };

declare 'MapStringVolumeSnapshot',
    as HashRef[VolumeSnapshot()];

declare 'SnapshotType',
    as (Int | Str);

declare 'GetVolumeSnapshotRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::GetVolumeSnapshotRequest'];

coerce 'GetVolumeSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::GetVolumeSnapshotRequest'->new($_) };

declare 'RepeatedGetVolumeSnapshotRequest',
    as ArrayRef[GetVolumeSnapshotRequest()];

coerce 'RepeatedGetVolumeSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::GetVolumeSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringGetVolumeSnapshotRequest',
    as HashRef[GetVolumeSnapshotRequest()];

declare 'ListVolumeSnapshotsRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::ListVolumeSnapshotsRequest'];

coerce 'ListVolumeSnapshotsRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::ListVolumeSnapshotsRequest'->new($_) };

declare 'RepeatedListVolumeSnapshotsRequest',
    as ArrayRef[ListVolumeSnapshotsRequest()];

coerce 'RepeatedListVolumeSnapshotsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::ListVolumeSnapshotsRequest'->new($_) } @$_ ] };

declare 'MapStringListVolumeSnapshotsRequest',
    as HashRef[ListVolumeSnapshotsRequest()];

declare 'ListVolumeSnapshotsResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::ListVolumeSnapshotsResponse'];

coerce 'ListVolumeSnapshotsResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::ListVolumeSnapshotsResponse'->new($_) };

declare 'RepeatedListVolumeSnapshotsResponse',
    as ArrayRef[ListVolumeSnapshotsResponse()];

coerce 'RepeatedListVolumeSnapshotsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::ListVolumeSnapshotsResponse'->new($_) } @$_ ] };

declare 'MapStringListVolumeSnapshotsResponse',
    as HashRef[ListVolumeSnapshotsResponse()];

declare 'DeleteVolumeSnapshotRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::DeleteVolumeSnapshotRequest'];

coerce 'DeleteVolumeSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::DeleteVolumeSnapshotRequest'->new($_) };

declare 'RepeatedDeleteVolumeSnapshotRequest',
    as ArrayRef[DeleteVolumeSnapshotRequest()];

coerce 'RepeatedDeleteVolumeSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::DeleteVolumeSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVolumeSnapshotRequest',
    as HashRef[DeleteVolumeSnapshotRequest()];

declare 'CreateVolumeSnapshotRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::CreateVolumeSnapshotRequest'];

coerce 'CreateVolumeSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::CreateVolumeSnapshotRequest'->new($_) };

declare 'RepeatedCreateVolumeSnapshotRequest',
    as ArrayRef[CreateVolumeSnapshotRequest()];

coerce 'RepeatedCreateVolumeSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::CreateVolumeSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVolumeSnapshotRequest',
    as HashRef[CreateVolumeSnapshotRequest()];

declare 'RestoreVolumeSnapshotRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::RestoreVolumeSnapshotRequest'];

coerce 'RestoreVolumeSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::RestoreVolumeSnapshotRequest'->new($_) };

declare 'RepeatedRestoreVolumeSnapshotRequest',
    as ArrayRef[RestoreVolumeSnapshotRequest()];

coerce 'RepeatedRestoreVolumeSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::RestoreVolumeSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreVolumeSnapshotRequest',
    as HashRef[RestoreVolumeSnapshotRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
