package Google::Cloud::Netapp::V1::Snapshot::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListSnapshotsRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsRequest'];

coerce 'ListSnapshotsRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsRequest'->new($_) };

declare 'RepeatedListSnapshotsRequest',
    as ArrayRef[ListSnapshotsRequest()];

coerce 'RepeatedListSnapshotsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsRequest'->new($_) } @$_ ] };

declare 'MapStringListSnapshotsRequest',
    as HashRef[ListSnapshotsRequest()];

declare 'ListSnapshotsResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsResponse'];

coerce 'ListSnapshotsResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsResponse'->new($_) };

declare 'RepeatedListSnapshotsResponse',
    as ArrayRef[ListSnapshotsResponse()];

coerce 'RepeatedListSnapshotsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsResponse'->new($_) } @$_ ] };

declare 'MapStringListSnapshotsResponse',
    as HashRef[ListSnapshotsResponse()];

declare 'GetSnapshotRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Snapshot::GetSnapshotRequest'];

coerce 'GetSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Snapshot::GetSnapshotRequest'->new($_) };

declare 'RepeatedGetSnapshotRequest',
    as ArrayRef[GetSnapshotRequest()];

coerce 'RepeatedGetSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Snapshot::GetSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringGetSnapshotRequest',
    as HashRef[GetSnapshotRequest()];

declare 'CreateSnapshotRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Snapshot::CreateSnapshotRequest'];

coerce 'CreateSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Snapshot::CreateSnapshotRequest'->new($_) };

declare 'RepeatedCreateSnapshotRequest',
    as ArrayRef[CreateSnapshotRequest()];

coerce 'RepeatedCreateSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Snapshot::CreateSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSnapshotRequest',
    as HashRef[CreateSnapshotRequest()];

declare 'DeleteSnapshotRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Snapshot::DeleteSnapshotRequest'];

coerce 'DeleteSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Snapshot::DeleteSnapshotRequest'->new($_) };

declare 'RepeatedDeleteSnapshotRequest',
    as ArrayRef[DeleteSnapshotRequest()];

coerce 'RepeatedDeleteSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Snapshot::DeleteSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSnapshotRequest',
    as HashRef[DeleteSnapshotRequest()];

declare 'UpdateSnapshotRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Snapshot::UpdateSnapshotRequest'];

coerce 'UpdateSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Snapshot::UpdateSnapshotRequest'->new($_) };

declare 'RepeatedUpdateSnapshotRequest',
    as ArrayRef[UpdateSnapshotRequest()];

coerce 'RepeatedUpdateSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Snapshot::UpdateSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSnapshotRequest',
    as HashRef[UpdateSnapshotRequest()];

declare 'Snapshot',
    as InstanceOf['Google::Cloud::Netapp::V1::Snapshot::Snapshot'];

coerce 'Snapshot',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Snapshot::Snapshot'->new($_) };

declare 'RepeatedSnapshot',
    as ArrayRef[Snapshot()];

coerce 'RepeatedSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Snapshot::Snapshot'->new($_) } @$_ ] };

declare 'MapStringSnapshot',
    as HashRef[Snapshot()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::Snapshot::Snapshot::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Snapshot::Snapshot::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Snapshot::Snapshot::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::Snapshot::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
