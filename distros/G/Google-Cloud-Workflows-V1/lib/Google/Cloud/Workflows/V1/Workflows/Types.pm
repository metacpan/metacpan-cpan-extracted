package Google::Cloud::Workflows::V1::Workflows::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecutionHistoryLevel',
    as (Int | Str);

declare 'Workflow',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::Workflow'];

coerce 'Workflow',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::Workflow'->new($_) };

declare 'RepeatedWorkflow',
    as ArrayRef[Workflow()];

coerce 'RepeatedWorkflow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::Workflow'->new($_) } @$_ ] };

declare 'MapStringWorkflow',
    as HashRef[Workflow()];

declare 'State',
    as (Int | Str);

declare 'CallLogLevel',
    as (Int | Str);

declare 'StateError',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::Workflow::StateError'];

coerce 'StateError',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::Workflow::StateError'->new($_) };

declare 'RepeatedStateError',
    as ArrayRef[StateError()];

coerce 'RepeatedStateError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::Workflow::StateError'->new($_) } @$_ ] };

declare 'MapStringStateError',
    as HashRef[StateError()];

declare 'Type',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::Workflow::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::Workflow::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::Workflow::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'UserEnvVarsEntry',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::Workflow::UserEnvVarsEntry'];

coerce 'UserEnvVarsEntry',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::Workflow::UserEnvVarsEntry'->new($_) };

declare 'RepeatedUserEnvVarsEntry',
    as ArrayRef[UserEnvVarsEntry()];

coerce 'RepeatedUserEnvVarsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::Workflow::UserEnvVarsEntry'->new($_) } @$_ ] };

declare 'MapStringUserEnvVarsEntry',
    as HashRef[UserEnvVarsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::Workflow::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::Workflow::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::Workflow::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'ListWorkflowsRequest',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::ListWorkflowsRequest'];

coerce 'ListWorkflowsRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::ListWorkflowsRequest'->new($_) };

declare 'RepeatedListWorkflowsRequest',
    as ArrayRef[ListWorkflowsRequest()];

coerce 'RepeatedListWorkflowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::ListWorkflowsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkflowsRequest',
    as HashRef[ListWorkflowsRequest()];

declare 'ListWorkflowsResponse',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::ListWorkflowsResponse'];

coerce 'ListWorkflowsResponse',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::ListWorkflowsResponse'->new($_) };

declare 'RepeatedListWorkflowsResponse',
    as ArrayRef[ListWorkflowsResponse()];

coerce 'RepeatedListWorkflowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::ListWorkflowsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkflowsResponse',
    as HashRef[ListWorkflowsResponse()];

declare 'GetWorkflowRequest',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::GetWorkflowRequest'];

coerce 'GetWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::GetWorkflowRequest'->new($_) };

declare 'RepeatedGetWorkflowRequest',
    as ArrayRef[GetWorkflowRequest()];

coerce 'RepeatedGetWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::GetWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkflowRequest',
    as HashRef[GetWorkflowRequest()];

declare 'CreateWorkflowRequest',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::CreateWorkflowRequest'];

coerce 'CreateWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::CreateWorkflowRequest'->new($_) };

declare 'RepeatedCreateWorkflowRequest',
    as ArrayRef[CreateWorkflowRequest()];

coerce 'RepeatedCreateWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::CreateWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkflowRequest',
    as HashRef[CreateWorkflowRequest()];

declare 'DeleteWorkflowRequest',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::DeleteWorkflowRequest'];

coerce 'DeleteWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::DeleteWorkflowRequest'->new($_) };

declare 'RepeatedDeleteWorkflowRequest',
    as ArrayRef[DeleteWorkflowRequest()];

coerce 'RepeatedDeleteWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::DeleteWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkflowRequest',
    as HashRef[DeleteWorkflowRequest()];

declare 'UpdateWorkflowRequest',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::UpdateWorkflowRequest'];

coerce 'UpdateWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::UpdateWorkflowRequest'->new($_) };

declare 'RepeatedUpdateWorkflowRequest',
    as ArrayRef[UpdateWorkflowRequest()];

coerce 'RepeatedUpdateWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::UpdateWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkflowRequest',
    as HashRef[UpdateWorkflowRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListWorkflowRevisionsRequest',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::ListWorkflowRevisionsRequest'];

coerce 'ListWorkflowRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::ListWorkflowRevisionsRequest'->new($_) };

declare 'RepeatedListWorkflowRevisionsRequest',
    as ArrayRef[ListWorkflowRevisionsRequest()];

coerce 'RepeatedListWorkflowRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::ListWorkflowRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkflowRevisionsRequest',
    as HashRef[ListWorkflowRevisionsRequest()];

declare 'ListWorkflowRevisionsResponse',
    as InstanceOf['Google::Cloud::Workflows::V1::Workflows::ListWorkflowRevisionsResponse'];

coerce 'ListWorkflowRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Workflows::V1::Workflows::ListWorkflowRevisionsResponse'->new($_) };

declare 'RepeatedListWorkflowRevisionsResponse',
    as ArrayRef[ListWorkflowRevisionsResponse()];

coerce 'RepeatedListWorkflowRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1::Workflows::ListWorkflowRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkflowRevisionsResponse',
    as HashRef[ListWorkflowRevisionsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Workflows::V1::Workflows::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
