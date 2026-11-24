package Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'State',
    as (Int | Str);

declare 'MachineLearningRun',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::MachineLearningRun'];

coerce 'MachineLearningRun',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::MachineLearningRun'->new($_) };

declare 'RepeatedMachineLearningRun',
    as ArrayRef[MachineLearningRun()];

coerce 'RepeatedMachineLearningRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::MachineLearningRun'->new($_) } @$_ ] };

declare 'MapStringMachineLearningRun',
    as HashRef[MachineLearningRun()];

declare 'Orchestrator',
    as (Int | Str);

declare 'RunPhase',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::MachineLearningRun::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::MachineLearningRun::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::MachineLearningRun::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ProfilerTarget',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ProfilerTarget'];

coerce 'ProfilerTarget',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ProfilerTarget'->new($_) };

declare 'RepeatedProfilerTarget',
    as ArrayRef[ProfilerTarget()];

coerce 'RepeatedProfilerTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ProfilerTarget'->new($_) } @$_ ] };

declare 'MapStringProfilerTarget',
    as HashRef[ProfilerTarget()];

declare 'ProfilerSession',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ProfilerSession'];

coerce 'ProfilerSession',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ProfilerSession'->new($_) };

declare 'RepeatedProfilerSession',
    as ArrayRef[ProfilerSession()];

coerce 'RepeatedProfilerSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ProfilerSession'->new($_) } @$_ ] };

declare 'MapStringProfilerSession',
    as HashRef[ProfilerSession()];

declare 'HostTracerLevel',
    as (Int | Str);

declare 'DeviceTracerLevel',
    as (Int | Str);

declare 'Kind',
    as (Int | Str);

declare 'PythonTracerLevel',
    as (Int | Str);

declare 'MonitoredEvent',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::MonitoredEvent'];

coerce 'MonitoredEvent',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::MonitoredEvent'->new($_) };

declare 'RepeatedMonitoredEvent',
    as ArrayRef[MonitoredEvent()];

coerce 'RepeatedMonitoredEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::MonitoredEvent'->new($_) } @$_ ] };

declare 'MapStringMonitoredEvent',
    as HashRef[MonitoredEvent()];

declare 'EventType',
    as (Int | Str);

declare 'ProfileSession',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ProfileSession'];

coerce 'ProfileSession',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ProfileSession'->new($_) };

declare 'RepeatedProfileSession',
    as ArrayRef[ProfileSession()];

coerce 'RepeatedProfileSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ProfileSession'->new($_) } @$_ ] };

declare 'MapStringProfileSession',
    as HashRef[ProfileSession()];

declare 'CreateMachineLearningRunRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateMachineLearningRunRequest'];

coerce 'CreateMachineLearningRunRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateMachineLearningRunRequest'->new($_) };

declare 'RepeatedCreateMachineLearningRunRequest',
    as ArrayRef[CreateMachineLearningRunRequest()];

coerce 'RepeatedCreateMachineLearningRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateMachineLearningRunRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMachineLearningRunRequest',
    as HashRef[CreateMachineLearningRunRequest()];

declare 'GetMachineLearningRunRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetMachineLearningRunRequest'];

coerce 'GetMachineLearningRunRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetMachineLearningRunRequest'->new($_) };

declare 'RepeatedGetMachineLearningRunRequest',
    as ArrayRef[GetMachineLearningRunRequest()];

coerce 'RepeatedGetMachineLearningRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetMachineLearningRunRequest'->new($_) } @$_ ] };

declare 'MapStringGetMachineLearningRunRequest',
    as HashRef[GetMachineLearningRunRequest()];

declare 'ListMachineLearningRunsRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMachineLearningRunsRequest'];

coerce 'ListMachineLearningRunsRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMachineLearningRunsRequest'->new($_) };

declare 'RepeatedListMachineLearningRunsRequest',
    as ArrayRef[ListMachineLearningRunsRequest()];

coerce 'RepeatedListMachineLearningRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMachineLearningRunsRequest'->new($_) } @$_ ] };

declare 'MapStringListMachineLearningRunsRequest',
    as HashRef[ListMachineLearningRunsRequest()];

declare 'ListMachineLearningRunsResponse',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMachineLearningRunsResponse'];

coerce 'ListMachineLearningRunsResponse',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMachineLearningRunsResponse'->new($_) };

declare 'RepeatedListMachineLearningRunsResponse',
    as ArrayRef[ListMachineLearningRunsResponse()];

coerce 'RepeatedListMachineLearningRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMachineLearningRunsResponse'->new($_) } @$_ ] };

declare 'MapStringListMachineLearningRunsResponse',
    as HashRef[ListMachineLearningRunsResponse()];

declare 'UpdateMachineLearningRunRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::UpdateMachineLearningRunRequest'];

coerce 'UpdateMachineLearningRunRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::UpdateMachineLearningRunRequest'->new($_) };

declare 'RepeatedUpdateMachineLearningRunRequest',
    as ArrayRef[UpdateMachineLearningRunRequest()];

coerce 'RepeatedUpdateMachineLearningRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::UpdateMachineLearningRunRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMachineLearningRunRequest',
    as HashRef[UpdateMachineLearningRunRequest()];

declare 'DeleteMachineLearningRunRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteMachineLearningRunRequest'];

coerce 'DeleteMachineLearningRunRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteMachineLearningRunRequest'->new($_) };

declare 'RepeatedDeleteMachineLearningRunRequest',
    as ArrayRef[DeleteMachineLearningRunRequest()];

coerce 'RepeatedDeleteMachineLearningRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteMachineLearningRunRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMachineLearningRunRequest',
    as HashRef[DeleteMachineLearningRunRequest()];

declare 'CreateProfilerTargetRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateProfilerTargetRequest'];

coerce 'CreateProfilerTargetRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateProfilerTargetRequest'->new($_) };

declare 'RepeatedCreateProfilerTargetRequest',
    as ArrayRef[CreateProfilerTargetRequest()];

coerce 'RepeatedCreateProfilerTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateProfilerTargetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProfilerTargetRequest',
    as HashRef[CreateProfilerTargetRequest()];

declare 'GetProfilerTargetRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetProfilerTargetRequest'];

coerce 'GetProfilerTargetRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetProfilerTargetRequest'->new($_) };

declare 'RepeatedGetProfilerTargetRequest',
    as ArrayRef[GetProfilerTargetRequest()];

coerce 'RepeatedGetProfilerTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetProfilerTargetRequest'->new($_) } @$_ ] };

declare 'MapStringGetProfilerTargetRequest',
    as HashRef[GetProfilerTargetRequest()];

declare 'ListProfilerTargetsRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerTargetsRequest'];

coerce 'ListProfilerTargetsRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerTargetsRequest'->new($_) };

declare 'RepeatedListProfilerTargetsRequest',
    as ArrayRef[ListProfilerTargetsRequest()];

coerce 'RepeatedListProfilerTargetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerTargetsRequest'->new($_) } @$_ ] };

declare 'MapStringListProfilerTargetsRequest',
    as HashRef[ListProfilerTargetsRequest()];

declare 'ListProfilerTargetsResponse',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerTargetsResponse'];

coerce 'ListProfilerTargetsResponse',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerTargetsResponse'->new($_) };

declare 'RepeatedListProfilerTargetsResponse',
    as ArrayRef[ListProfilerTargetsResponse()];

coerce 'RepeatedListProfilerTargetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerTargetsResponse'->new($_) } @$_ ] };

declare 'MapStringListProfilerTargetsResponse',
    as HashRef[ListProfilerTargetsResponse()];

declare 'DeleteProfilerTargetRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteProfilerTargetRequest'];

coerce 'DeleteProfilerTargetRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteProfilerTargetRequest'->new($_) };

declare 'RepeatedDeleteProfilerTargetRequest',
    as ArrayRef[DeleteProfilerTargetRequest()];

coerce 'RepeatedDeleteProfilerTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteProfilerTargetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProfilerTargetRequest',
    as HashRef[DeleteProfilerTargetRequest()];

declare 'CreateProfilerSessionRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateProfilerSessionRequest'];

coerce 'CreateProfilerSessionRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateProfilerSessionRequest'->new($_) };

declare 'RepeatedCreateProfilerSessionRequest',
    as ArrayRef[CreateProfilerSessionRequest()];

coerce 'RepeatedCreateProfilerSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateProfilerSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProfilerSessionRequest',
    as HashRef[CreateProfilerSessionRequest()];

declare 'GetProfilerSessionRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetProfilerSessionRequest'];

coerce 'GetProfilerSessionRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetProfilerSessionRequest'->new($_) };

declare 'RepeatedGetProfilerSessionRequest',
    as ArrayRef[GetProfilerSessionRequest()];

coerce 'RepeatedGetProfilerSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetProfilerSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetProfilerSessionRequest',
    as HashRef[GetProfilerSessionRequest()];

declare 'ListProfilerSessionsRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerSessionsRequest'];

coerce 'ListProfilerSessionsRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerSessionsRequest'->new($_) };

declare 'RepeatedListProfilerSessionsRequest',
    as ArrayRef[ListProfilerSessionsRequest()];

coerce 'RepeatedListProfilerSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringListProfilerSessionsRequest',
    as HashRef[ListProfilerSessionsRequest()];

declare 'ListProfilerSessionsResponse',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerSessionsResponse'];

coerce 'ListProfilerSessionsResponse',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerSessionsResponse'->new($_) };

declare 'RepeatedListProfilerSessionsResponse',
    as ArrayRef[ListProfilerSessionsResponse()];

coerce 'RepeatedListProfilerSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfilerSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringListProfilerSessionsResponse',
    as HashRef[ListProfilerSessionsResponse()];

declare 'DeleteProfilerSessionRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteProfilerSessionRequest'];

coerce 'DeleteProfilerSessionRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteProfilerSessionRequest'->new($_) };

declare 'RepeatedDeleteProfilerSessionRequest',
    as ArrayRef[DeleteProfilerSessionRequest()];

coerce 'RepeatedDeleteProfilerSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteProfilerSessionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProfilerSessionRequest',
    as HashRef[DeleteProfilerSessionRequest()];

declare 'GetProfileSessionRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetProfileSessionRequest'];

coerce 'GetProfileSessionRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetProfileSessionRequest'->new($_) };

declare 'RepeatedGetProfileSessionRequest',
    as ArrayRef[GetProfileSessionRequest()];

coerce 'RepeatedGetProfileSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetProfileSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetProfileSessionRequest',
    as HashRef[GetProfileSessionRequest()];

declare 'ListProfileSessionsRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfileSessionsRequest'];

coerce 'ListProfileSessionsRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfileSessionsRequest'->new($_) };

declare 'RepeatedListProfileSessionsRequest',
    as ArrayRef[ListProfileSessionsRequest()];

coerce 'RepeatedListProfileSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfileSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringListProfileSessionsRequest',
    as HashRef[ListProfileSessionsRequest()];

declare 'ListProfileSessionsResponse',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfileSessionsResponse'];

coerce 'ListProfileSessionsResponse',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfileSessionsResponse'->new($_) };

declare 'RepeatedListProfileSessionsResponse',
    as ArrayRef[ListProfileSessionsResponse()];

coerce 'RepeatedListProfileSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListProfileSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringListProfileSessionsResponse',
    as HashRef[ListProfileSessionsResponse()];

declare 'CreateMonitoredEventRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateMonitoredEventRequest'];

coerce 'CreateMonitoredEventRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateMonitoredEventRequest'->new($_) };

declare 'RepeatedCreateMonitoredEventRequest',
    as ArrayRef[CreateMonitoredEventRequest()];

coerce 'RepeatedCreateMonitoredEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::CreateMonitoredEventRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMonitoredEventRequest',
    as HashRef[CreateMonitoredEventRequest()];

declare 'GetMonitoredEventRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetMonitoredEventRequest'];

coerce 'GetMonitoredEventRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetMonitoredEventRequest'->new($_) };

declare 'RepeatedGetMonitoredEventRequest',
    as ArrayRef[GetMonitoredEventRequest()];

coerce 'RepeatedGetMonitoredEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GetMonitoredEventRequest'->new($_) } @$_ ] };

declare 'MapStringGetMonitoredEventRequest',
    as HashRef[GetMonitoredEventRequest()];

declare 'ListMonitoredEventsRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMonitoredEventsRequest'];

coerce 'ListMonitoredEventsRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMonitoredEventsRequest'->new($_) };

declare 'RepeatedListMonitoredEventsRequest',
    as ArrayRef[ListMonitoredEventsRequest()];

coerce 'RepeatedListMonitoredEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMonitoredEventsRequest'->new($_) } @$_ ] };

declare 'MapStringListMonitoredEventsRequest',
    as HashRef[ListMonitoredEventsRequest()];

declare 'ListMonitoredEventsResponse',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMonitoredEventsResponse'];

coerce 'ListMonitoredEventsResponse',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMonitoredEventsResponse'->new($_) };

declare 'RepeatedListMonitoredEventsResponse',
    as ArrayRef[ListMonitoredEventsResponse()];

coerce 'RepeatedListMonitoredEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::ListMonitoredEventsResponse'->new($_) } @$_ ] };

declare 'MapStringListMonitoredEventsResponse',
    as HashRef[ListMonitoredEventsResponse()];

declare 'UpdateMonitoredEventRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::UpdateMonitoredEventRequest'];

coerce 'UpdateMonitoredEventRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::UpdateMonitoredEventRequest'->new($_) };

declare 'RepeatedUpdateMonitoredEventRequest',
    as ArrayRef[UpdateMonitoredEventRequest()];

coerce 'RepeatedUpdateMonitoredEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::UpdateMonitoredEventRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMonitoredEventRequest',
    as HashRef[UpdateMonitoredEventRequest()];

declare 'DeleteMonitoredEventRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteMonitoredEventRequest'];

coerce 'DeleteMonitoredEventRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteMonitoredEventRequest'->new($_) };

declare 'RepeatedDeleteMonitoredEventRequest',
    as ArrayRef[DeleteMonitoredEventRequest()];

coerce 'RepeatedDeleteMonitoredEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::DeleteMonitoredEventRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMonitoredEventRequest',
    as HashRef[DeleteMonitoredEventRequest()];

declare 'Configs',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs'];

coerce 'Configs',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs'->new($_) };

declare 'RepeatedConfigs',
    as ArrayRef[Configs()];

coerce 'RepeatedConfigs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs'->new($_) } @$_ ] };

declare 'MapStringConfigs',
    as HashRef[Configs()];

declare 'UserConfigsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs::UserConfigsEntry'];

coerce 'UserConfigsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs::UserConfigsEntry'->new($_) };

declare 'RepeatedUserConfigsEntry',
    as ArrayRef[UserConfigsEntry()];

coerce 'RepeatedUserConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs::UserConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringUserConfigsEntry',
    as HashRef[UserConfigsEntry()];

declare 'SoftwareConfigsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs::SoftwareConfigsEntry'];

coerce 'SoftwareConfigsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs::SoftwareConfigsEntry'->new($_) };

declare 'RepeatedSoftwareConfigsEntry',
    as ArrayRef[SoftwareConfigsEntry()];

coerce 'RepeatedSoftwareConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs::SoftwareConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringSoftwareConfigsEntry',
    as HashRef[SoftwareConfigsEntry()];

declare 'HardwareConfigsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs::HardwareConfigsEntry'];

coerce 'HardwareConfigsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs::HardwareConfigsEntry'->new($_) };

declare 'RepeatedHardwareConfigsEntry',
    as ArrayRef[HardwareConfigsEntry()];

coerce 'RepeatedHardwareConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Configs::HardwareConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringHardwareConfigsEntry',
    as HashRef[HardwareConfigsEntry()];

declare 'Metrics',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Metrics'];

coerce 'Metrics',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Metrics'->new($_) };

declare 'RepeatedMetrics',
    as ArrayRef[Metrics()];

coerce 'RepeatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Metrics'->new($_) } @$_ ] };

declare 'MapStringMetrics',
    as HashRef[Metrics()];

declare 'Artifacts',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Artifacts'];

coerce 'Artifacts',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Artifacts'->new($_) };

declare 'RepeatedArtifacts',
    as ArrayRef[Artifacts()];

coerce 'RepeatedArtifacts',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Artifacts'->new($_) } @$_ ] };

declare 'MapStringArtifacts',
    as HashRef[Artifacts()];

declare 'Tool',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Tool'];

coerce 'Tool',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Tool'->new($_) };

declare 'RepeatedTool',
    as ArrayRef[Tool()];

coerce 'RepeatedTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Tool'->new($_) } @$_ ] };

declare 'MapStringTool',
    as HashRef[Tool()];

declare 'WorkloadDetails',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::WorkloadDetails'];

coerce 'WorkloadDetails',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::WorkloadDetails'->new($_) };

declare 'RepeatedWorkloadDetails',
    as ArrayRef[WorkloadDetails()];

coerce 'RepeatedWorkloadDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::WorkloadDetails'->new($_) } @$_ ] };

declare 'MapStringWorkloadDetails',
    as HashRef[WorkloadDetails()];

declare 'GKEWorkloadDetails',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GKEWorkloadDetails'];

coerce 'GKEWorkloadDetails',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GKEWorkloadDetails'->new($_) };

declare 'RepeatedGKEWorkloadDetails',
    as ArrayRef[GKEWorkloadDetails()];

coerce 'RepeatedGKEWorkloadDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GKEWorkloadDetails'->new($_) } @$_ ] };

declare 'MapStringGKEWorkloadDetails',
    as HashRef[GKEWorkloadDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GKEWorkloadDetails::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GKEWorkloadDetails::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::GKEWorkloadDetails::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Xprof',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Xprof'];

coerce 'Xprof',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Xprof'->new($_) };

declare 'RepeatedXprof',
    as ArrayRef[Xprof()];

coerce 'RepeatedXprof',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Xprof'->new($_) } @$_ ] };

declare 'MapStringXprof',
    as HashRef[Xprof()];

declare 'Smon',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Smon'];

coerce 'Smon',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Smon'->new($_) };

declare 'RepeatedSmon',
    as ArrayRef[Smon()];

coerce 'RepeatedSmon',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Smon'->new($_) } @$_ ] };

declare 'MapStringSmon',
    as HashRef[Smon()];

declare 'AnalyzerReport',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::AnalyzerReport'];

coerce 'AnalyzerReport',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::AnalyzerReport'->new($_) };

declare 'RepeatedAnalyzerReport',
    as ArrayRef[AnalyzerReport()];

coerce 'RepeatedAnalyzerReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::AnalyzerReport'->new($_) } @$_ ] };

declare 'MapStringAnalyzerReport',
    as HashRef[AnalyzerReport()];

declare 'DetectionState',
    as (Int | Str);

declare 'RecommendedAction',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::RecommendedAction'];

coerce 'RecommendedAction',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::RecommendedAction'->new($_) };

declare 'RepeatedRecommendedAction',
    as ArrayRef[RecommendedAction()];

coerce 'RepeatedRecommendedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::RecommendedAction'->new($_) } @$_ ] };

declare 'MapStringRecommendedAction',
    as HashRef[RecommendedAction()];

1;

__END__

=head1 NAME

Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRuns::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
