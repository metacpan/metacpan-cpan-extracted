package Google::Dataflow::V1beta3::Snapshots::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SnapshotState',
    as (Int | Str);

declare 'PubsubSnapshotMetadata',
    as InstanceOf['Google::Dataflow::V1beta3::Snapshots::PubsubSnapshotMetadata'];

coerce 'PubsubSnapshotMetadata',
    from HashRef, via { 'Google::Dataflow::V1beta3::Snapshots::PubsubSnapshotMetadata'->new($_) };

declare 'RepeatedPubsubSnapshotMetadata',
    as ArrayRef[PubsubSnapshotMetadata()];

coerce 'RepeatedPubsubSnapshotMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Snapshots::PubsubSnapshotMetadata'->new($_) } @$_ ] };

declare 'MapStringPubsubSnapshotMetadata',
    as HashRef[PubsubSnapshotMetadata()];

declare 'Snapshot',
    as InstanceOf['Google::Dataflow::V1beta3::Snapshots::Snapshot'];

coerce 'Snapshot',
    from HashRef, via { 'Google::Dataflow::V1beta3::Snapshots::Snapshot'->new($_) };

declare 'RepeatedSnapshot',
    as ArrayRef[Snapshot()];

coerce 'RepeatedSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Snapshots::Snapshot'->new($_) } @$_ ] };

declare 'MapStringSnapshot',
    as HashRef[Snapshot()];

declare 'GetSnapshotRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Snapshots::GetSnapshotRequest'];

coerce 'GetSnapshotRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Snapshots::GetSnapshotRequest'->new($_) };

declare 'RepeatedGetSnapshotRequest',
    as ArrayRef[GetSnapshotRequest()];

coerce 'RepeatedGetSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Snapshots::GetSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringGetSnapshotRequest',
    as HashRef[GetSnapshotRequest()];

declare 'DeleteSnapshotRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotRequest'];

coerce 'DeleteSnapshotRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotRequest'->new($_) };

declare 'RepeatedDeleteSnapshotRequest',
    as ArrayRef[DeleteSnapshotRequest()];

coerce 'RepeatedDeleteSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSnapshotRequest',
    as HashRef[DeleteSnapshotRequest()];

declare 'DeleteSnapshotResponse',
    as InstanceOf['Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotResponse'];

coerce 'DeleteSnapshotResponse',
    from HashRef, via { 'Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotResponse'->new($_) };

declare 'RepeatedDeleteSnapshotResponse',
    as ArrayRef[DeleteSnapshotResponse()];

coerce 'RepeatedDeleteSnapshotResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotResponse'->new($_) } @$_ ] };

declare 'MapStringDeleteSnapshotResponse',
    as HashRef[DeleteSnapshotResponse()];

declare 'ListSnapshotsRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Snapshots::ListSnapshotsRequest'];

coerce 'ListSnapshotsRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Snapshots::ListSnapshotsRequest'->new($_) };

declare 'RepeatedListSnapshotsRequest',
    as ArrayRef[ListSnapshotsRequest()];

coerce 'RepeatedListSnapshotsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Snapshots::ListSnapshotsRequest'->new($_) } @$_ ] };

declare 'MapStringListSnapshotsRequest',
    as HashRef[ListSnapshotsRequest()];

declare 'ListSnapshotsResponse',
    as InstanceOf['Google::Dataflow::V1beta3::Snapshots::ListSnapshotsResponse'];

coerce 'ListSnapshotsResponse',
    from HashRef, via { 'Google::Dataflow::V1beta3::Snapshots::ListSnapshotsResponse'->new($_) };

declare 'RepeatedListSnapshotsResponse',
    as ArrayRef[ListSnapshotsResponse()];

coerce 'RepeatedListSnapshotsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Snapshots::ListSnapshotsResponse'->new($_) } @$_ ] };

declare 'MapStringListSnapshotsResponse',
    as HashRef[ListSnapshotsResponse()];

1;

__END__

=head1 NAME

Google::Dataflow::V1beta3::Snapshots::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
