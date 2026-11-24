package Google::Cloud::Datacatalog::Lineage::V1::Lineage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DependencyType',
    as (Int | Str);

declare 'Process',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::Process'];

coerce 'Process',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Process'->new($_) };

declare 'RepeatedProcess',
    as ArrayRef[Process()];

coerce 'RepeatedProcess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Process'->new($_) } @$_ ] };

declare 'MapStringProcess',
    as HashRef[Process()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::Process::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Process::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Process::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'Run',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::Run'];

coerce 'Run',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Run'->new($_) };

declare 'RepeatedRun',
    as ArrayRef[Run()];

coerce 'RepeatedRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Run'->new($_) } @$_ ] };

declare 'MapStringRun',
    as HashRef[Run()];

declare 'State',
    as (Int | Str);

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::Run::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Run::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Run::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'LineageEvent',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageEvent'];

coerce 'LineageEvent',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageEvent'->new($_) };

declare 'RepeatedLineageEvent',
    as ArrayRef[LineageEvent()];

coerce 'RepeatedLineageEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageEvent'->new($_) } @$_ ] };

declare 'MapStringLineageEvent',
    as HashRef[LineageEvent()];

declare 'EventLink',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::EventLink'];

coerce 'EventLink',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::EventLink'->new($_) };

declare 'RepeatedEventLink',
    as ArrayRef[EventLink()];

coerce 'RepeatedEventLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::EventLink'->new($_) } @$_ ] };

declare 'MapStringEventLink',
    as HashRef[EventLink()];

declare 'DependencyInfo',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::DependencyInfo'];

coerce 'DependencyInfo',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::DependencyInfo'->new($_) };

declare 'RepeatedDependencyInfo',
    as ArrayRef[DependencyInfo()];

coerce 'RepeatedDependencyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::DependencyInfo'->new($_) } @$_ ] };

declare 'MapStringDependencyInfo',
    as HashRef[DependencyInfo()];

declare 'EntityReference',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::EntityReference'];

coerce 'EntityReference',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::EntityReference'->new($_) };

declare 'RepeatedEntityReference',
    as ArrayRef[EntityReference()];

coerce 'RepeatedEntityReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::EntityReference'->new($_) } @$_ ] };

declare 'MapStringEntityReference',
    as HashRef[EntityReference()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'ProcessOpenLineageRunEventRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessOpenLineageRunEventRequest'];

coerce 'ProcessOpenLineageRunEventRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessOpenLineageRunEventRequest'->new($_) };

declare 'RepeatedProcessOpenLineageRunEventRequest',
    as ArrayRef[ProcessOpenLineageRunEventRequest()];

coerce 'RepeatedProcessOpenLineageRunEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessOpenLineageRunEventRequest'->new($_) } @$_ ] };

declare 'MapStringProcessOpenLineageRunEventRequest',
    as HashRef[ProcessOpenLineageRunEventRequest()];

declare 'ProcessOpenLineageRunEventResponse',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessOpenLineageRunEventResponse'];

coerce 'ProcessOpenLineageRunEventResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessOpenLineageRunEventResponse'->new($_) };

declare 'RepeatedProcessOpenLineageRunEventResponse',
    as ArrayRef[ProcessOpenLineageRunEventResponse()];

coerce 'RepeatedProcessOpenLineageRunEventResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessOpenLineageRunEventResponse'->new($_) } @$_ ] };

declare 'MapStringProcessOpenLineageRunEventResponse',
    as HashRef[ProcessOpenLineageRunEventResponse()];

declare 'CreateProcessRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::CreateProcessRequest'];

coerce 'CreateProcessRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::CreateProcessRequest'->new($_) };

declare 'RepeatedCreateProcessRequest',
    as ArrayRef[CreateProcessRequest()];

coerce 'RepeatedCreateProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::CreateProcessRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProcessRequest',
    as HashRef[CreateProcessRequest()];

declare 'UpdateProcessRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::UpdateProcessRequest'];

coerce 'UpdateProcessRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::UpdateProcessRequest'->new($_) };

declare 'RepeatedUpdateProcessRequest',
    as ArrayRef[UpdateProcessRequest()];

coerce 'RepeatedUpdateProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::UpdateProcessRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProcessRequest',
    as HashRef[UpdateProcessRequest()];

declare 'GetProcessRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::GetProcessRequest'];

coerce 'GetProcessRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::GetProcessRequest'->new($_) };

declare 'RepeatedGetProcessRequest',
    as ArrayRef[GetProcessRequest()];

coerce 'RepeatedGetProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::GetProcessRequest'->new($_) } @$_ ] };

declare 'MapStringGetProcessRequest',
    as HashRef[GetProcessRequest()];

declare 'ListProcessesRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListProcessesRequest'];

coerce 'ListProcessesRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListProcessesRequest'->new($_) };

declare 'RepeatedListProcessesRequest',
    as ArrayRef[ListProcessesRequest()];

coerce 'RepeatedListProcessesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListProcessesRequest'->new($_) } @$_ ] };

declare 'MapStringListProcessesRequest',
    as HashRef[ListProcessesRequest()];

declare 'ListProcessesResponse',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListProcessesResponse'];

coerce 'ListProcessesResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListProcessesResponse'->new($_) };

declare 'RepeatedListProcessesResponse',
    as ArrayRef[ListProcessesResponse()];

coerce 'RepeatedListProcessesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListProcessesResponse'->new($_) } @$_ ] };

declare 'MapStringListProcessesResponse',
    as HashRef[ListProcessesResponse()];

declare 'DeleteProcessRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::DeleteProcessRequest'];

coerce 'DeleteProcessRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::DeleteProcessRequest'->new($_) };

declare 'RepeatedDeleteProcessRequest',
    as ArrayRef[DeleteProcessRequest()];

coerce 'RepeatedDeleteProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::DeleteProcessRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProcessRequest',
    as HashRef[DeleteProcessRequest()];

declare 'CreateRunRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::CreateRunRequest'];

coerce 'CreateRunRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::CreateRunRequest'->new($_) };

declare 'RepeatedCreateRunRequest',
    as ArrayRef[CreateRunRequest()];

coerce 'RepeatedCreateRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::CreateRunRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRunRequest',
    as HashRef[CreateRunRequest()];

declare 'UpdateRunRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::UpdateRunRequest'];

coerce 'UpdateRunRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::UpdateRunRequest'->new($_) };

declare 'RepeatedUpdateRunRequest',
    as ArrayRef[UpdateRunRequest()];

coerce 'RepeatedUpdateRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::UpdateRunRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRunRequest',
    as HashRef[UpdateRunRequest()];

declare 'GetRunRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::GetRunRequest'];

coerce 'GetRunRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::GetRunRequest'->new($_) };

declare 'RepeatedGetRunRequest',
    as ArrayRef[GetRunRequest()];

coerce 'RepeatedGetRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::GetRunRequest'->new($_) } @$_ ] };

declare 'MapStringGetRunRequest',
    as HashRef[GetRunRequest()];

declare 'ListRunsRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListRunsRequest'];

coerce 'ListRunsRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListRunsRequest'->new($_) };

declare 'RepeatedListRunsRequest',
    as ArrayRef[ListRunsRequest()];

coerce 'RepeatedListRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListRunsRequest'->new($_) } @$_ ] };

declare 'MapStringListRunsRequest',
    as HashRef[ListRunsRequest()];

declare 'ListRunsResponse',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListRunsResponse'];

coerce 'ListRunsResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListRunsResponse'->new($_) };

declare 'RepeatedListRunsResponse',
    as ArrayRef[ListRunsResponse()];

coerce 'RepeatedListRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListRunsResponse'->new($_) } @$_ ] };

declare 'MapStringListRunsResponse',
    as HashRef[ListRunsResponse()];

declare 'DeleteRunRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::DeleteRunRequest'];

coerce 'DeleteRunRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::DeleteRunRequest'->new($_) };

declare 'RepeatedDeleteRunRequest',
    as ArrayRef[DeleteRunRequest()];

coerce 'RepeatedDeleteRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::DeleteRunRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRunRequest',
    as HashRef[DeleteRunRequest()];

declare 'CreateLineageEventRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::CreateLineageEventRequest'];

coerce 'CreateLineageEventRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::CreateLineageEventRequest'->new($_) };

declare 'RepeatedCreateLineageEventRequest',
    as ArrayRef[CreateLineageEventRequest()];

coerce 'RepeatedCreateLineageEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::CreateLineageEventRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLineageEventRequest',
    as HashRef[CreateLineageEventRequest()];

declare 'GetLineageEventRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::GetLineageEventRequest'];

coerce 'GetLineageEventRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::GetLineageEventRequest'->new($_) };

declare 'RepeatedGetLineageEventRequest',
    as ArrayRef[GetLineageEventRequest()];

coerce 'RepeatedGetLineageEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::GetLineageEventRequest'->new($_) } @$_ ] };

declare 'MapStringGetLineageEventRequest',
    as HashRef[GetLineageEventRequest()];

declare 'ListLineageEventsRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListLineageEventsRequest'];

coerce 'ListLineageEventsRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListLineageEventsRequest'->new($_) };

declare 'RepeatedListLineageEventsRequest',
    as ArrayRef[ListLineageEventsRequest()];

coerce 'RepeatedListLineageEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListLineageEventsRequest'->new($_) } @$_ ] };

declare 'MapStringListLineageEventsRequest',
    as HashRef[ListLineageEventsRequest()];

declare 'ListLineageEventsResponse',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListLineageEventsResponse'];

coerce 'ListLineageEventsResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListLineageEventsResponse'->new($_) };

declare 'RepeatedListLineageEventsResponse',
    as ArrayRef[ListLineageEventsResponse()];

coerce 'RepeatedListLineageEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ListLineageEventsResponse'->new($_) } @$_ ] };

declare 'MapStringListLineageEventsResponse',
    as HashRef[ListLineageEventsResponse()];

declare 'DeleteLineageEventRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::DeleteLineageEventRequest'];

coerce 'DeleteLineageEventRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::DeleteLineageEventRequest'->new($_) };

declare 'RepeatedDeleteLineageEventRequest',
    as ArrayRef[DeleteLineageEventRequest()];

coerce 'RepeatedDeleteLineageEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::DeleteLineageEventRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLineageEventRequest',
    as HashRef[DeleteLineageEventRequest()];

declare 'SearchLinksRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLinksRequest'];

coerce 'SearchLinksRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLinksRequest'->new($_) };

declare 'RepeatedSearchLinksRequest',
    as ArrayRef[SearchLinksRequest()];

coerce 'RepeatedSearchLinksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLinksRequest'->new($_) } @$_ ] };

declare 'MapStringSearchLinksRequest',
    as HashRef[SearchLinksRequest()];

declare 'MultipleEntityReference',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::MultipleEntityReference'];

coerce 'MultipleEntityReference',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::MultipleEntityReference'->new($_) };

declare 'RepeatedMultipleEntityReference',
    as ArrayRef[MultipleEntityReference()];

coerce 'RepeatedMultipleEntityReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::MultipleEntityReference'->new($_) } @$_ ] };

declare 'MapStringMultipleEntityReference',
    as HashRef[MultipleEntityReference()];

declare 'SearchLinksResponse',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLinksResponse'];

coerce 'SearchLinksResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLinksResponse'->new($_) };

declare 'RepeatedSearchLinksResponse',
    as ArrayRef[SearchLinksResponse()];

coerce 'RepeatedSearchLinksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLinksResponse'->new($_) } @$_ ] };

declare 'MapStringSearchLinksResponse',
    as HashRef[SearchLinksResponse()];

declare 'Link',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::Link'];

coerce 'Link',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Link'->new($_) };

declare 'RepeatedLink',
    as ArrayRef[Link()];

coerce 'RepeatedLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Link'->new($_) } @$_ ] };

declare 'MapStringLink',
    as HashRef[Link()];

declare 'DependencyInfo',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::Link::DependencyInfo'];

coerce 'DependencyInfo',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Link::DependencyInfo'->new($_) };

declare 'RepeatedDependencyInfo',
    as ArrayRef[DependencyInfo()];

coerce 'RepeatedDependencyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Link::DependencyInfo'->new($_) } @$_ ] };

declare 'MapStringDependencyInfo',
    as HashRef[DependencyInfo()];

declare 'BatchSearchLinkProcessesRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::BatchSearchLinkProcessesRequest'];

coerce 'BatchSearchLinkProcessesRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::BatchSearchLinkProcessesRequest'->new($_) };

declare 'RepeatedBatchSearchLinkProcessesRequest',
    as ArrayRef[BatchSearchLinkProcessesRequest()];

coerce 'RepeatedBatchSearchLinkProcessesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::BatchSearchLinkProcessesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchSearchLinkProcessesRequest',
    as HashRef[BatchSearchLinkProcessesRequest()];

declare 'BatchSearchLinkProcessesResponse',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::BatchSearchLinkProcessesResponse'];

coerce 'BatchSearchLinkProcessesResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::BatchSearchLinkProcessesResponse'->new($_) };

declare 'RepeatedBatchSearchLinkProcessesResponse',
    as ArrayRef[BatchSearchLinkProcessesResponse()];

coerce 'RepeatedBatchSearchLinkProcessesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::BatchSearchLinkProcessesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchSearchLinkProcessesResponse',
    as HashRef[BatchSearchLinkProcessesResponse()];

declare 'ProcessLinks',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessLinks'];

coerce 'ProcessLinks',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessLinks'->new($_) };

declare 'RepeatedProcessLinks',
    as ArrayRef[ProcessLinks()];

coerce 'RepeatedProcessLinks',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessLinks'->new($_) } @$_ ] };

declare 'MapStringProcessLinks',
    as HashRef[ProcessLinks()];

declare 'ProcessLinkInfo',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessLinkInfo'];

coerce 'ProcessLinkInfo',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessLinkInfo'->new($_) };

declare 'RepeatedProcessLinkInfo',
    as ArrayRef[ProcessLinkInfo()];

coerce 'RepeatedProcessLinkInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::ProcessLinkInfo'->new($_) } @$_ ] };

declare 'MapStringProcessLinkInfo',
    as HashRef[ProcessLinkInfo()];

declare 'Origin',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::Origin'];

coerce 'Origin',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Origin'->new($_) };

declare 'RepeatedOrigin',
    as ArrayRef[Origin()];

coerce 'RepeatedOrigin',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::Origin'->new($_) } @$_ ] };

declare 'MapStringOrigin',
    as HashRef[Origin()];

declare 'SourceType',
    as (Int | Str);

declare 'LineageLink',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageLink'];

coerce 'LineageLink',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageLink'->new($_) };

declare 'RepeatedLineageLink',
    as ArrayRef[LineageLink()];

coerce 'RepeatedLineageLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageLink'->new($_) } @$_ ] };

declare 'MapStringLineageLink',
    as HashRef[LineageLink()];

declare 'LineageProcess',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageLink::LineageProcess'];

coerce 'LineageProcess',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageLink::LineageProcess'->new($_) };

declare 'RepeatedLineageProcess',
    as ArrayRef[LineageProcess()];

coerce 'RepeatedLineageProcess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageLink::LineageProcess'->new($_) } @$_ ] };

declare 'MapStringLineageProcess',
    as HashRef[LineageProcess()];

declare 'DependencyInfo',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageLink::DependencyInfo'];

coerce 'DependencyInfo',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageLink::DependencyInfo'->new($_) };

declare 'RepeatedDependencyInfo',
    as ArrayRef[DependencyInfo()];

coerce 'RepeatedDependencyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::LineageLink::DependencyInfo'->new($_) } @$_ ] };

declare 'MapStringDependencyInfo',
    as HashRef[DependencyInfo()];

declare 'SearchLineageStreamingRequest',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest'];

coerce 'SearchLineageStreamingRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest'->new($_) };

declare 'RepeatedSearchLineageStreamingRequest',
    as ArrayRef[SearchLineageStreamingRequest()];

coerce 'RepeatedSearchLineageStreamingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest'->new($_) } @$_ ] };

declare 'MapStringSearchLineageStreamingRequest',
    as HashRef[SearchLineageStreamingRequest()];

declare 'SearchDirection',
    as (Int | Str);

declare 'EntitySet',
    as (Int | Str);

declare 'SearchFilters',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest::SearchFilters'];

coerce 'SearchFilters',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest::SearchFilters'->new($_) };

declare 'RepeatedSearchFilters',
    as ArrayRef[SearchFilters()];

coerce 'RepeatedSearchFilters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest::SearchFilters'->new($_) } @$_ ] };

declare 'MapStringSearchFilters',
    as HashRef[SearchFilters()];

declare 'SearchLimits',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest::SearchLimits'];

coerce 'SearchLimits',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest::SearchLimits'->new($_) };

declare 'RepeatedSearchLimits',
    as ArrayRef[SearchLimits()];

coerce 'RepeatedSearchLimits',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest::SearchLimits'->new($_) } @$_ ] };

declare 'MapStringSearchLimits',
    as HashRef[SearchLimits()];

declare 'RootCriteria',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest::RootCriteria'];

coerce 'RootCriteria',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest::RootCriteria'->new($_) };

declare 'RepeatedRootCriteria',
    as ArrayRef[RootCriteria()];

coerce 'RepeatedRootCriteria',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingRequest::RootCriteria'->new($_) } @$_ ] };

declare 'MapStringRootCriteria',
    as HashRef[RootCriteria()];

declare 'SearchLineageStreamingResponse',
    as InstanceOf['Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingResponse'];

coerce 'SearchLineageStreamingResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingResponse'->new($_) };

declare 'RepeatedSearchLineageStreamingResponse',
    as ArrayRef[SearchLineageStreamingResponse()];

coerce 'RepeatedSearchLineageStreamingResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::Lineage::V1::Lineage::SearchLineageStreamingResponse'->new($_) } @$_ ] };

declare 'MapStringSearchLineageStreamingResponse',
    as HashRef[SearchLineageStreamingResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::Lineage::V1::Lineage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
