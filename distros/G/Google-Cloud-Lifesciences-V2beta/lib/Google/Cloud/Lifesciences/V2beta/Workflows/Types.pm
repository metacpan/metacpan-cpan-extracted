package Google::Cloud::Lifesciences::V2beta::Workflows::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RunPipelineRequest',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::RunPipelineRequest'];

coerce 'RunPipelineRequest',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::RunPipelineRequest'->new($_) };

declare 'RepeatedRunPipelineRequest',
    as ArrayRef[RunPipelineRequest()];

coerce 'RepeatedRunPipelineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::RunPipelineRequest'->new($_) } @$_ ] };

declare 'MapStringRunPipelineRequest',
    as HashRef[RunPipelineRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::RunPipelineRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::RunPipelineRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::RunPipelineRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RunPipelineResponse',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::RunPipelineResponse'];

coerce 'RunPipelineResponse',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::RunPipelineResponse'->new($_) };

declare 'RepeatedRunPipelineResponse',
    as ArrayRef[RunPipelineResponse()];

coerce 'RepeatedRunPipelineResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::RunPipelineResponse'->new($_) } @$_ ] };

declare 'MapStringRunPipelineResponse',
    as HashRef[RunPipelineResponse()];

declare 'Pipeline',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Pipeline'];

coerce 'Pipeline',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Pipeline'->new($_) };

declare 'RepeatedPipeline',
    as ArrayRef[Pipeline()];

coerce 'RepeatedPipeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Pipeline'->new($_) } @$_ ] };

declare 'MapStringPipeline',
    as HashRef[Pipeline()];

declare 'EnvironmentEntry',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Pipeline::EnvironmentEntry'];

coerce 'EnvironmentEntry',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Pipeline::EnvironmentEntry'->new($_) };

declare 'RepeatedEnvironmentEntry',
    as ArrayRef[EnvironmentEntry()];

coerce 'RepeatedEnvironmentEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Pipeline::EnvironmentEntry'->new($_) } @$_ ] };

declare 'MapStringEnvironmentEntry',
    as HashRef[EnvironmentEntry()];

declare 'Action',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'EnvironmentEntry',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Action::EnvironmentEntry'];

coerce 'EnvironmentEntry',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Action::EnvironmentEntry'->new($_) };

declare 'RepeatedEnvironmentEntry',
    as ArrayRef[EnvironmentEntry()];

coerce 'RepeatedEnvironmentEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Action::EnvironmentEntry'->new($_) } @$_ ] };

declare 'MapStringEnvironmentEntry',
    as HashRef[EnvironmentEntry()];

declare 'PortMappingsEntry',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Action::PortMappingsEntry'];

coerce 'PortMappingsEntry',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Action::PortMappingsEntry'->new($_) };

declare 'RepeatedPortMappingsEntry',
    as ArrayRef[PortMappingsEntry()];

coerce 'RepeatedPortMappingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Action::PortMappingsEntry'->new($_) } @$_ ] };

declare 'MapStringPortMappingsEntry',
    as HashRef[PortMappingsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Action::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Action::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Action::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Secret',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Secret'];

coerce 'Secret',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Secret'->new($_) };

declare 'RepeatedSecret',
    as ArrayRef[Secret()];

coerce 'RepeatedSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Secret'->new($_) } @$_ ] };

declare 'MapStringSecret',
    as HashRef[Secret()];

declare 'Mount',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Mount'];

coerce 'Mount',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Mount'->new($_) };

declare 'RepeatedMount',
    as ArrayRef[Mount()];

coerce 'RepeatedMount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Mount'->new($_) } @$_ ] };

declare 'MapStringMount',
    as HashRef[Mount()];

declare 'Resources',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Resources'];

coerce 'Resources',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Resources'->new($_) };

declare 'RepeatedResources',
    as ArrayRef[Resources()];

coerce 'RepeatedResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Resources'->new($_) } @$_ ] };

declare 'MapStringResources',
    as HashRef[Resources()];

declare 'VirtualMachine',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::VirtualMachine'];

coerce 'VirtualMachine',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::VirtualMachine'->new($_) };

declare 'RepeatedVirtualMachine',
    as ArrayRef[VirtualMachine()];

coerce 'RepeatedVirtualMachine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::VirtualMachine'->new($_) } @$_ ] };

declare 'MapStringVirtualMachine',
    as HashRef[VirtualMachine()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::VirtualMachine::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::VirtualMachine::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::VirtualMachine::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ServiceAccount',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'Accelerator',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Accelerator'];

coerce 'Accelerator',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Accelerator'->new($_) };

declare 'RepeatedAccelerator',
    as ArrayRef[Accelerator()];

coerce 'RepeatedAccelerator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Accelerator'->new($_) } @$_ ] };

declare 'MapStringAccelerator',
    as HashRef[Accelerator()];

declare 'Network',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Network'];

coerce 'Network',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Network'->new($_) };

declare 'RepeatedNetwork',
    as ArrayRef[Network()];

coerce 'RepeatedNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Network'->new($_) } @$_ ] };

declare 'MapStringNetwork',
    as HashRef[Network()];

declare 'Disk',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Disk'];

coerce 'Disk',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Disk'->new($_) };

declare 'RepeatedDisk',
    as ArrayRef[Disk()];

coerce 'RepeatedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Disk'->new($_) } @$_ ] };

declare 'MapStringDisk',
    as HashRef[Disk()];

declare 'Volume',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Volume'];

coerce 'Volume',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Volume'->new($_) };

declare 'RepeatedVolume',
    as ArrayRef[Volume()];

coerce 'RepeatedVolume',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Volume'->new($_) } @$_ ] };

declare 'MapStringVolume',
    as HashRef[Volume()];

declare 'PersistentDisk',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::PersistentDisk'];

coerce 'PersistentDisk',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::PersistentDisk'->new($_) };

declare 'RepeatedPersistentDisk',
    as ArrayRef[PersistentDisk()];

coerce 'RepeatedPersistentDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::PersistentDisk'->new($_) } @$_ ] };

declare 'MapStringPersistentDisk',
    as HashRef[PersistentDisk()];

declare 'ExistingDisk',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::ExistingDisk'];

coerce 'ExistingDisk',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::ExistingDisk'->new($_) };

declare 'RepeatedExistingDisk',
    as ArrayRef[ExistingDisk()];

coerce 'RepeatedExistingDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::ExistingDisk'->new($_) } @$_ ] };

declare 'MapStringExistingDisk',
    as HashRef[ExistingDisk()];

declare 'NFSMount',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::NFSMount'];

coerce 'NFSMount',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::NFSMount'->new($_) };

declare 'RepeatedNFSMount',
    as ArrayRef[NFSMount()];

coerce 'RepeatedNFSMount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::NFSMount'->new($_) } @$_ ] };

declare 'MapStringNFSMount',
    as HashRef[NFSMount()];

declare 'Metadata',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Metadata::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Metadata::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Metadata::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Event',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'DelayedEvent',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::DelayedEvent'];

coerce 'DelayedEvent',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::DelayedEvent'->new($_) };

declare 'RepeatedDelayedEvent',
    as ArrayRef[DelayedEvent()];

coerce 'RepeatedDelayedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::DelayedEvent'->new($_) } @$_ ] };

declare 'MapStringDelayedEvent',
    as HashRef[DelayedEvent()];

declare 'WorkerAssignedEvent',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::WorkerAssignedEvent'];

coerce 'WorkerAssignedEvent',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::WorkerAssignedEvent'->new($_) };

declare 'RepeatedWorkerAssignedEvent',
    as ArrayRef[WorkerAssignedEvent()];

coerce 'RepeatedWorkerAssignedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::WorkerAssignedEvent'->new($_) } @$_ ] };

declare 'MapStringWorkerAssignedEvent',
    as HashRef[WorkerAssignedEvent()];

declare 'WorkerReleasedEvent',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::WorkerReleasedEvent'];

coerce 'WorkerReleasedEvent',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::WorkerReleasedEvent'->new($_) };

declare 'RepeatedWorkerReleasedEvent',
    as ArrayRef[WorkerReleasedEvent()];

coerce 'RepeatedWorkerReleasedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::WorkerReleasedEvent'->new($_) } @$_ ] };

declare 'MapStringWorkerReleasedEvent',
    as HashRef[WorkerReleasedEvent()];

declare 'PullStartedEvent',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::PullStartedEvent'];

coerce 'PullStartedEvent',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::PullStartedEvent'->new($_) };

declare 'RepeatedPullStartedEvent',
    as ArrayRef[PullStartedEvent()];

coerce 'RepeatedPullStartedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::PullStartedEvent'->new($_) } @$_ ] };

declare 'MapStringPullStartedEvent',
    as HashRef[PullStartedEvent()];

declare 'PullStoppedEvent',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::PullStoppedEvent'];

coerce 'PullStoppedEvent',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::PullStoppedEvent'->new($_) };

declare 'RepeatedPullStoppedEvent',
    as ArrayRef[PullStoppedEvent()];

coerce 'RepeatedPullStoppedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::PullStoppedEvent'->new($_) } @$_ ] };

declare 'MapStringPullStoppedEvent',
    as HashRef[PullStoppedEvent()];

declare 'ContainerStartedEvent',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::ContainerStartedEvent'];

coerce 'ContainerStartedEvent',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::ContainerStartedEvent'->new($_) };

declare 'RepeatedContainerStartedEvent',
    as ArrayRef[ContainerStartedEvent()];

coerce 'RepeatedContainerStartedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::ContainerStartedEvent'->new($_) } @$_ ] };

declare 'MapStringContainerStartedEvent',
    as HashRef[ContainerStartedEvent()];

declare 'PortMappingsEntry',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::ContainerStartedEvent::PortMappingsEntry'];

coerce 'PortMappingsEntry',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::ContainerStartedEvent::PortMappingsEntry'->new($_) };

declare 'RepeatedPortMappingsEntry',
    as ArrayRef[PortMappingsEntry()];

coerce 'RepeatedPortMappingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::ContainerStartedEvent::PortMappingsEntry'->new($_) } @$_ ] };

declare 'MapStringPortMappingsEntry',
    as HashRef[PortMappingsEntry()];

declare 'ContainerStoppedEvent',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::ContainerStoppedEvent'];

coerce 'ContainerStoppedEvent',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::ContainerStoppedEvent'->new($_) };

declare 'RepeatedContainerStoppedEvent',
    as ArrayRef[ContainerStoppedEvent()];

coerce 'RepeatedContainerStoppedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::ContainerStoppedEvent'->new($_) } @$_ ] };

declare 'MapStringContainerStoppedEvent',
    as HashRef[ContainerStoppedEvent()];

declare 'UnexpectedExitStatusEvent',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::UnexpectedExitStatusEvent'];

coerce 'UnexpectedExitStatusEvent',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::UnexpectedExitStatusEvent'->new($_) };

declare 'RepeatedUnexpectedExitStatusEvent',
    as ArrayRef[UnexpectedExitStatusEvent()];

coerce 'RepeatedUnexpectedExitStatusEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::UnexpectedExitStatusEvent'->new($_) } @$_ ] };

declare 'MapStringUnexpectedExitStatusEvent',
    as HashRef[UnexpectedExitStatusEvent()];

declare 'ContainerKilledEvent',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::ContainerKilledEvent'];

coerce 'ContainerKilledEvent',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::ContainerKilledEvent'->new($_) };

declare 'RepeatedContainerKilledEvent',
    as ArrayRef[ContainerKilledEvent()];

coerce 'RepeatedContainerKilledEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::ContainerKilledEvent'->new($_) } @$_ ] };

declare 'MapStringContainerKilledEvent',
    as HashRef[ContainerKilledEvent()];

declare 'FailedEvent',
    as InstanceOf['Google::Cloud::Lifesciences::V2beta::Workflows::FailedEvent'];

coerce 'FailedEvent',
    from HashRef, via { 'Google::Cloud::Lifesciences::V2beta::Workflows::FailedEvent'->new($_) };

declare 'RepeatedFailedEvent',
    as ArrayRef[FailedEvent()];

coerce 'RepeatedFailedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lifesciences::V2beta::Workflows::FailedEvent'->new($_) } @$_ ] };

declare 'MapStringFailedEvent',
    as HashRef[FailedEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Lifesciences::V2beta::Workflows::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
