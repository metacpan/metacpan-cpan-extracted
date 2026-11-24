package Google::Cloud::Batch::V1::Job::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Job',
    as InstanceOf['Google::Cloud::Batch::V1::Job::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Batch::V1::Job::Job::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::Job::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::Job::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'LogsPolicy',
    as InstanceOf['Google::Cloud::Batch::V1::Job::LogsPolicy'];

coerce 'LogsPolicy',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::LogsPolicy'->new($_) };

declare 'RepeatedLogsPolicy',
    as ArrayRef[LogsPolicy()];

coerce 'RepeatedLogsPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::LogsPolicy'->new($_) } @$_ ] };

declare 'MapStringLogsPolicy',
    as HashRef[LogsPolicy()];

declare 'Destination',
    as (Int | Str);

declare 'CloudLoggingOption',
    as InstanceOf['Google::Cloud::Batch::V1::Job::LogsPolicy::CloudLoggingOption'];

coerce 'CloudLoggingOption',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::LogsPolicy::CloudLoggingOption'->new($_) };

declare 'RepeatedCloudLoggingOption',
    as ArrayRef[CloudLoggingOption()];

coerce 'RepeatedCloudLoggingOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::LogsPolicy::CloudLoggingOption'->new($_) } @$_ ] };

declare 'MapStringCloudLoggingOption',
    as HashRef[CloudLoggingOption()];

declare 'JobStatus',
    as InstanceOf['Google::Cloud::Batch::V1::Job::JobStatus'];

coerce 'JobStatus',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::JobStatus'->new($_) };

declare 'RepeatedJobStatus',
    as ArrayRef[JobStatus()];

coerce 'RepeatedJobStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::JobStatus'->new($_) } @$_ ] };

declare 'MapStringJobStatus',
    as HashRef[JobStatus()];

declare 'State',
    as (Int | Str);

declare 'InstanceStatus',
    as InstanceOf['Google::Cloud::Batch::V1::Job::JobStatus::InstanceStatus'];

coerce 'InstanceStatus',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::JobStatus::InstanceStatus'->new($_) };

declare 'RepeatedInstanceStatus',
    as ArrayRef[InstanceStatus()];

coerce 'RepeatedInstanceStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::JobStatus::InstanceStatus'->new($_) } @$_ ] };

declare 'MapStringInstanceStatus',
    as HashRef[InstanceStatus()];

declare 'TaskGroupStatus',
    as InstanceOf['Google::Cloud::Batch::V1::Job::JobStatus::TaskGroupStatus'];

coerce 'TaskGroupStatus',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::JobStatus::TaskGroupStatus'->new($_) };

declare 'RepeatedTaskGroupStatus',
    as ArrayRef[TaskGroupStatus()];

coerce 'RepeatedTaskGroupStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::JobStatus::TaskGroupStatus'->new($_) } @$_ ] };

declare 'MapStringTaskGroupStatus',
    as HashRef[TaskGroupStatus()];

declare 'CountsEntry',
    as InstanceOf['Google::Cloud::Batch::V1::Job::JobStatus::TaskGroupStatus::CountsEntry'];

coerce 'CountsEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::JobStatus::TaskGroupStatus::CountsEntry'->new($_) };

declare 'RepeatedCountsEntry',
    as ArrayRef[CountsEntry()];

coerce 'RepeatedCountsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::JobStatus::TaskGroupStatus::CountsEntry'->new($_) } @$_ ] };

declare 'MapStringCountsEntry',
    as HashRef[CountsEntry()];

declare 'TaskGroupsEntry',
    as InstanceOf['Google::Cloud::Batch::V1::Job::JobStatus::TaskGroupsEntry'];

coerce 'TaskGroupsEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::JobStatus::TaskGroupsEntry'->new($_) };

declare 'RepeatedTaskGroupsEntry',
    as ArrayRef[TaskGroupsEntry()];

coerce 'RepeatedTaskGroupsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::JobStatus::TaskGroupsEntry'->new($_) } @$_ ] };

declare 'MapStringTaskGroupsEntry',
    as HashRef[TaskGroupsEntry()];

declare 'JobNotification',
    as InstanceOf['Google::Cloud::Batch::V1::Job::JobNotification'];

coerce 'JobNotification',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::JobNotification'->new($_) };

declare 'RepeatedJobNotification',
    as ArrayRef[JobNotification()];

coerce 'RepeatedJobNotification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::JobNotification'->new($_) } @$_ ] };

declare 'MapStringJobNotification',
    as HashRef[JobNotification()];

declare 'Type',
    as (Int | Str);

declare 'Message',
    as InstanceOf['Google::Cloud::Batch::V1::Job::JobNotification::Message'];

coerce 'Message',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::JobNotification::Message'->new($_) };

declare 'RepeatedMessage',
    as ArrayRef[Message()];

coerce 'RepeatedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::JobNotification::Message'->new($_) } @$_ ] };

declare 'MapStringMessage',
    as HashRef[Message()];

declare 'AllocationPolicy',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy'];

coerce 'AllocationPolicy',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy'->new($_) };

declare 'RepeatedAllocationPolicy',
    as ArrayRef[AllocationPolicy()];

coerce 'RepeatedAllocationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy'->new($_) } @$_ ] };

declare 'MapStringAllocationPolicy',
    as HashRef[AllocationPolicy()];

declare 'ProvisioningModel',
    as (Int | Str);

declare 'LocationPolicy',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::LocationPolicy'];

coerce 'LocationPolicy',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::LocationPolicy'->new($_) };

declare 'RepeatedLocationPolicy',
    as ArrayRef[LocationPolicy()];

coerce 'RepeatedLocationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::LocationPolicy'->new($_) } @$_ ] };

declare 'MapStringLocationPolicy',
    as HashRef[LocationPolicy()];

declare 'Disk',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::Disk'];

coerce 'Disk',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::Disk'->new($_) };

declare 'RepeatedDisk',
    as ArrayRef[Disk()];

coerce 'RepeatedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::Disk'->new($_) } @$_ ] };

declare 'MapStringDisk',
    as HashRef[Disk()];

declare 'AttachedDisk',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::AttachedDisk'];

coerce 'AttachedDisk',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::AttachedDisk'->new($_) };

declare 'RepeatedAttachedDisk',
    as ArrayRef[AttachedDisk()];

coerce 'RepeatedAttachedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::AttachedDisk'->new($_) } @$_ ] };

declare 'MapStringAttachedDisk',
    as HashRef[AttachedDisk()];

declare 'Accelerator',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::Accelerator'];

coerce 'Accelerator',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::Accelerator'->new($_) };

declare 'RepeatedAccelerator',
    as ArrayRef[Accelerator()];

coerce 'RepeatedAccelerator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::Accelerator'->new($_) } @$_ ] };

declare 'MapStringAccelerator',
    as HashRef[Accelerator()];

declare 'InstancePolicy',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::InstancePolicy'];

coerce 'InstancePolicy',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::InstancePolicy'->new($_) };

declare 'RepeatedInstancePolicy',
    as ArrayRef[InstancePolicy()];

coerce 'RepeatedInstancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::InstancePolicy'->new($_) } @$_ ] };

declare 'MapStringInstancePolicy',
    as HashRef[InstancePolicy()];

declare 'InstancePolicyOrTemplate',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::InstancePolicyOrTemplate'];

coerce 'InstancePolicyOrTemplate',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::InstancePolicyOrTemplate'->new($_) };

declare 'RepeatedInstancePolicyOrTemplate',
    as ArrayRef[InstancePolicyOrTemplate()];

coerce 'RepeatedInstancePolicyOrTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::InstancePolicyOrTemplate'->new($_) } @$_ ] };

declare 'MapStringInstancePolicyOrTemplate',
    as HashRef[InstancePolicyOrTemplate()];

declare 'NetworkInterface',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::NetworkInterface'];

coerce 'NetworkInterface',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::NetworkInterface'->new($_) };

declare 'RepeatedNetworkInterface',
    as ArrayRef[NetworkInterface()];

coerce 'RepeatedNetworkInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::NetworkInterface'->new($_) } @$_ ] };

declare 'MapStringNetworkInterface',
    as HashRef[NetworkInterface()];

declare 'NicType',
    as (Int | Str);

declare 'NetworkPolicy',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::NetworkPolicy'];

coerce 'NetworkPolicy',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::NetworkPolicy'->new($_) };

declare 'RepeatedNetworkPolicy',
    as ArrayRef[NetworkPolicy()];

coerce 'RepeatedNetworkPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::NetworkPolicy'->new($_) } @$_ ] };

declare 'MapStringNetworkPolicy',
    as HashRef[NetworkPolicy()];

declare 'PlacementPolicy',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::PlacementPolicy'];

coerce 'PlacementPolicy',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::PlacementPolicy'->new($_) };

declare 'RepeatedPlacementPolicy',
    as ArrayRef[PlacementPolicy()];

coerce 'RepeatedPlacementPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::PlacementPolicy'->new($_) } @$_ ] };

declare 'MapStringPlacementPolicy',
    as HashRef[PlacementPolicy()];

declare 'InstanceFlexibilityPolicy',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::InstanceFlexibilityPolicy'];

coerce 'InstanceFlexibilityPolicy',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::InstanceFlexibilityPolicy'->new($_) };

declare 'RepeatedInstanceFlexibilityPolicy',
    as ArrayRef[InstanceFlexibilityPolicy()];

coerce 'RepeatedInstanceFlexibilityPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::InstanceFlexibilityPolicy'->new($_) } @$_ ] };

declare 'MapStringInstanceFlexibilityPolicy',
    as HashRef[InstanceFlexibilityPolicy()];

declare 'InstanceSelectionsEntry',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::InstanceFlexibilityPolicy::InstanceSelectionsEntry'];

coerce 'InstanceSelectionsEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::InstanceFlexibilityPolicy::InstanceSelectionsEntry'->new($_) };

declare 'RepeatedInstanceSelectionsEntry',
    as ArrayRef[InstanceSelectionsEntry()];

coerce 'RepeatedInstanceSelectionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::InstanceFlexibilityPolicy::InstanceSelectionsEntry'->new($_) } @$_ ] };

declare 'MapStringInstanceSelectionsEntry',
    as HashRef[InstanceSelectionsEntry()];

declare 'InstanceSelection',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::InstanceSelection'];

coerce 'InstanceSelection',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::InstanceSelection'->new($_) };

declare 'RepeatedInstanceSelection',
    as ArrayRef[InstanceSelection()];

coerce 'RepeatedInstanceSelection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::InstanceSelection'->new($_) } @$_ ] };

declare 'MapStringInstanceSelection',
    as HashRef[InstanceSelection()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Batch::V1::Job::AllocationPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::AllocationPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TaskGroup',
    as InstanceOf['Google::Cloud::Batch::V1::Job::TaskGroup'];

coerce 'TaskGroup',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::TaskGroup'->new($_) };

declare 'RepeatedTaskGroup',
    as ArrayRef[TaskGroup()];

coerce 'RepeatedTaskGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::TaskGroup'->new($_) } @$_ ] };

declare 'MapStringTaskGroup',
    as HashRef[TaskGroup()];

declare 'SchedulingPolicy',
    as (Int | Str);

declare 'ServiceAccount',
    as InstanceOf['Google::Cloud::Batch::V1::Job::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Cloud::Batch::V1::Job::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Job::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

1;

__END__

=head1 NAME

Google::Cloud::Batch::V1::Job::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
