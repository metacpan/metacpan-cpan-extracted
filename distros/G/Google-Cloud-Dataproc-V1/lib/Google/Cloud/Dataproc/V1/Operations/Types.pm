package Google::Cloud::Dataproc::V1::Operations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BatchOperationMetadata',
    as InstanceOf['Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata'];

coerce 'BatchOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata'->new($_) };

declare 'RepeatedBatchOperationMetadata',
    as ArrayRef[BatchOperationMetadata()];

coerce 'RepeatedBatchOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchOperationMetadata',
    as HashRef[BatchOperationMetadata()];

declare 'BatchOperationType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'SessionOperationMetadata',
    as InstanceOf['Google::Cloud::Dataproc::V1::Operations::SessionOperationMetadata'];

coerce 'SessionOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Operations::SessionOperationMetadata'->new($_) };

declare 'RepeatedSessionOperationMetadata',
    as ArrayRef[SessionOperationMetadata()];

coerce 'RepeatedSessionOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Operations::SessionOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringSessionOperationMetadata',
    as HashRef[SessionOperationMetadata()];

declare 'SessionOperationType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Operations::SessionOperationMetadata::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Operations::SessionOperationMetadata::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Operations::SessionOperationMetadata::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ClusterOperationStatus',
    as InstanceOf['Google::Cloud::Dataproc::V1::Operations::ClusterOperationStatus'];

coerce 'ClusterOperationStatus',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Operations::ClusterOperationStatus'->new($_) };

declare 'RepeatedClusterOperationStatus',
    as ArrayRef[ClusterOperationStatus()];

coerce 'RepeatedClusterOperationStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Operations::ClusterOperationStatus'->new($_) } @$_ ] };

declare 'MapStringClusterOperationStatus',
    as HashRef[ClusterOperationStatus()];

declare 'State',
    as (Int | Str);

declare 'ClusterOperationMetadata',
    as InstanceOf['Google::Cloud::Dataproc::V1::Operations::ClusterOperationMetadata'];

coerce 'ClusterOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Operations::ClusterOperationMetadata'->new($_) };

declare 'RepeatedClusterOperationMetadata',
    as ArrayRef[ClusterOperationMetadata()];

coerce 'RepeatedClusterOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Operations::ClusterOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringClusterOperationMetadata',
    as HashRef[ClusterOperationMetadata()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Operations::ClusterOperationMetadata::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Operations::ClusterOperationMetadata::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Operations::ClusterOperationMetadata::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NodeGroupOperationMetadata',
    as InstanceOf['Google::Cloud::Dataproc::V1::Operations::NodeGroupOperationMetadata'];

coerce 'NodeGroupOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Operations::NodeGroupOperationMetadata'->new($_) };

declare 'RepeatedNodeGroupOperationMetadata',
    as ArrayRef[NodeGroupOperationMetadata()];

coerce 'RepeatedNodeGroupOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Operations::NodeGroupOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringNodeGroupOperationMetadata',
    as HashRef[NodeGroupOperationMetadata()];

declare 'NodeGroupOperationType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Operations::NodeGroupOperationMetadata::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Operations::NodeGroupOperationMetadata::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Operations::NodeGroupOperationMetadata::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::Operations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
