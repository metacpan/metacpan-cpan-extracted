package Google::Dataflow::V1beta3::Streaming::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TopologyConfig',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::TopologyConfig'];

coerce 'TopologyConfig',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::TopologyConfig'->new($_) };

declare 'RepeatedTopologyConfig',
    as ArrayRef[TopologyConfig()];

coerce 'RepeatedTopologyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::TopologyConfig'->new($_) } @$_ ] };

declare 'MapStringTopologyConfig',
    as HashRef[TopologyConfig()];

declare 'UserStageToComputationNameMapEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::TopologyConfig::UserStageToComputationNameMapEntry'];

coerce 'UserStageToComputationNameMapEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::TopologyConfig::UserStageToComputationNameMapEntry'->new($_) };

declare 'RepeatedUserStageToComputationNameMapEntry',
    as ArrayRef[UserStageToComputationNameMapEntry()];

coerce 'RepeatedUserStageToComputationNameMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::TopologyConfig::UserStageToComputationNameMapEntry'->new($_) } @$_ ] };

declare 'MapStringUserStageToComputationNameMapEntry',
    as HashRef[UserStageToComputationNameMapEntry()];

declare 'PubsubLocation',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::PubsubLocation'];

coerce 'PubsubLocation',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::PubsubLocation'->new($_) };

declare 'RepeatedPubsubLocation',
    as ArrayRef[PubsubLocation()];

coerce 'RepeatedPubsubLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::PubsubLocation'->new($_) } @$_ ] };

declare 'MapStringPubsubLocation',
    as HashRef[PubsubLocation()];

declare 'StreamingStageLocation',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::StreamingStageLocation'];

coerce 'StreamingStageLocation',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::StreamingStageLocation'->new($_) };

declare 'RepeatedStreamingStageLocation',
    as ArrayRef[StreamingStageLocation()];

coerce 'RepeatedStreamingStageLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::StreamingStageLocation'->new($_) } @$_ ] };

declare 'MapStringStreamingStageLocation',
    as HashRef[StreamingStageLocation()];

declare 'StreamingSideInputLocation',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::StreamingSideInputLocation'];

coerce 'StreamingSideInputLocation',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::StreamingSideInputLocation'->new($_) };

declare 'RepeatedStreamingSideInputLocation',
    as ArrayRef[StreamingSideInputLocation()];

coerce 'RepeatedStreamingSideInputLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::StreamingSideInputLocation'->new($_) } @$_ ] };

declare 'MapStringStreamingSideInputLocation',
    as HashRef[StreamingSideInputLocation()];

declare 'CustomSourceLocation',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::CustomSourceLocation'];

coerce 'CustomSourceLocation',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::CustomSourceLocation'->new($_) };

declare 'RepeatedCustomSourceLocation',
    as ArrayRef[CustomSourceLocation()];

coerce 'RepeatedCustomSourceLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::CustomSourceLocation'->new($_) } @$_ ] };

declare 'MapStringCustomSourceLocation',
    as HashRef[CustomSourceLocation()];

declare 'StreamLocation',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::StreamLocation'];

coerce 'StreamLocation',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::StreamLocation'->new($_) };

declare 'RepeatedStreamLocation',
    as ArrayRef[StreamLocation()];

coerce 'RepeatedStreamLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::StreamLocation'->new($_) } @$_ ] };

declare 'MapStringStreamLocation',
    as HashRef[StreamLocation()];

declare 'StateFamilyConfig',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::StateFamilyConfig'];

coerce 'StateFamilyConfig',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::StateFamilyConfig'->new($_) };

declare 'RepeatedStateFamilyConfig',
    as ArrayRef[StateFamilyConfig()];

coerce 'RepeatedStateFamilyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::StateFamilyConfig'->new($_) } @$_ ] };

declare 'MapStringStateFamilyConfig',
    as HashRef[StateFamilyConfig()];

declare 'ComputationTopology',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::ComputationTopology'];

coerce 'ComputationTopology',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::ComputationTopology'->new($_) };

declare 'RepeatedComputationTopology',
    as ArrayRef[ComputationTopology()];

coerce 'RepeatedComputationTopology',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::ComputationTopology'->new($_) } @$_ ] };

declare 'MapStringComputationTopology',
    as HashRef[ComputationTopology()];

declare 'KeyRangeLocation',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::KeyRangeLocation'];

coerce 'KeyRangeLocation',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::KeyRangeLocation'->new($_) };

declare 'RepeatedKeyRangeLocation',
    as ArrayRef[KeyRangeLocation()];

coerce 'RepeatedKeyRangeLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::KeyRangeLocation'->new($_) } @$_ ] };

declare 'MapStringKeyRangeLocation',
    as HashRef[KeyRangeLocation()];

declare 'MountedDataDisk',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::MountedDataDisk'];

coerce 'MountedDataDisk',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::MountedDataDisk'->new($_) };

declare 'RepeatedMountedDataDisk',
    as ArrayRef[MountedDataDisk()];

coerce 'RepeatedMountedDataDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::MountedDataDisk'->new($_) } @$_ ] };

declare 'MapStringMountedDataDisk',
    as HashRef[MountedDataDisk()];

declare 'DataDiskAssignment',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::DataDiskAssignment'];

coerce 'DataDiskAssignment',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::DataDiskAssignment'->new($_) };

declare 'RepeatedDataDiskAssignment',
    as ArrayRef[DataDiskAssignment()];

coerce 'RepeatedDataDiskAssignment',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::DataDiskAssignment'->new($_) } @$_ ] };

declare 'MapStringDataDiskAssignment',
    as HashRef[DataDiskAssignment()];

declare 'KeyRangeDataDiskAssignment',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::KeyRangeDataDiskAssignment'];

coerce 'KeyRangeDataDiskAssignment',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::KeyRangeDataDiskAssignment'->new($_) };

declare 'RepeatedKeyRangeDataDiskAssignment',
    as ArrayRef[KeyRangeDataDiskAssignment()];

coerce 'RepeatedKeyRangeDataDiskAssignment',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::KeyRangeDataDiskAssignment'->new($_) } @$_ ] };

declare 'MapStringKeyRangeDataDiskAssignment',
    as HashRef[KeyRangeDataDiskAssignment()];

declare 'StreamingComputationRanges',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::StreamingComputationRanges'];

coerce 'StreamingComputationRanges',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::StreamingComputationRanges'->new($_) };

declare 'RepeatedStreamingComputationRanges',
    as ArrayRef[StreamingComputationRanges()];

coerce 'RepeatedStreamingComputationRanges',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::StreamingComputationRanges'->new($_) } @$_ ] };

declare 'MapStringStreamingComputationRanges',
    as HashRef[StreamingComputationRanges()];

declare 'StreamingApplianceSnapshotConfig',
    as InstanceOf['Google::Dataflow::V1beta3::Streaming::StreamingApplianceSnapshotConfig'];

coerce 'StreamingApplianceSnapshotConfig',
    from HashRef, via { 'Google::Dataflow::V1beta3::Streaming::StreamingApplianceSnapshotConfig'->new($_) };

declare 'RepeatedStreamingApplianceSnapshotConfig',
    as ArrayRef[StreamingApplianceSnapshotConfig()];

coerce 'RepeatedStreamingApplianceSnapshotConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Streaming::StreamingApplianceSnapshotConfig'->new($_) } @$_ ] };

declare 'MapStringStreamingApplianceSnapshotConfig',
    as HashRef[StreamingApplianceSnapshotConfig()];

1;

__END__

=head1 NAME

Google::Dataflow::V1beta3::Streaming::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
