package Google::Cloud::Workflows::V1beta::Workflows::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Workflow',
    as InstanceOf['Google::Cloud::Workflows::V1beta::Workflows::Workflow'];

coerce 'Workflow',
    from HashRef, via { 'Google::Cloud::Workflows::V1beta::Workflows::Workflow'->new($_) };

declare 'RepeatedWorkflow',
    as ArrayRef[Workflow()];

coerce 'RepeatedWorkflow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1beta::Workflows::Workflow'->new($_) } @$_ ] };

declare 'MapStringWorkflow',
    as HashRef[Workflow()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Workflows::V1beta::Workflows::Workflow::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Workflows::V1beta::Workflows::Workflow::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1beta::Workflows::Workflow::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListWorkflowsRequest',
    as InstanceOf['Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsRequest'];

coerce 'ListWorkflowsRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsRequest'->new($_) };

declare 'RepeatedListWorkflowsRequest',
    as ArrayRef[ListWorkflowsRequest()];

coerce 'RepeatedListWorkflowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkflowsRequest',
    as HashRef[ListWorkflowsRequest()];

declare 'ListWorkflowsResponse',
    as InstanceOf['Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsResponse'];

coerce 'ListWorkflowsResponse',
    from HashRef, via { 'Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsResponse'->new($_) };

declare 'RepeatedListWorkflowsResponse',
    as ArrayRef[ListWorkflowsResponse()];

coerce 'RepeatedListWorkflowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkflowsResponse',
    as HashRef[ListWorkflowsResponse()];

declare 'GetWorkflowRequest',
    as InstanceOf['Google::Cloud::Workflows::V1beta::Workflows::GetWorkflowRequest'];

coerce 'GetWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1beta::Workflows::GetWorkflowRequest'->new($_) };

declare 'RepeatedGetWorkflowRequest',
    as ArrayRef[GetWorkflowRequest()];

coerce 'RepeatedGetWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1beta::Workflows::GetWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkflowRequest',
    as HashRef[GetWorkflowRequest()];

declare 'CreateWorkflowRequest',
    as InstanceOf['Google::Cloud::Workflows::V1beta::Workflows::CreateWorkflowRequest'];

coerce 'CreateWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1beta::Workflows::CreateWorkflowRequest'->new($_) };

declare 'RepeatedCreateWorkflowRequest',
    as ArrayRef[CreateWorkflowRequest()];

coerce 'RepeatedCreateWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1beta::Workflows::CreateWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkflowRequest',
    as HashRef[CreateWorkflowRequest()];

declare 'DeleteWorkflowRequest',
    as InstanceOf['Google::Cloud::Workflows::V1beta::Workflows::DeleteWorkflowRequest'];

coerce 'DeleteWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1beta::Workflows::DeleteWorkflowRequest'->new($_) };

declare 'RepeatedDeleteWorkflowRequest',
    as ArrayRef[DeleteWorkflowRequest()];

coerce 'RepeatedDeleteWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1beta::Workflows::DeleteWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkflowRequest',
    as HashRef[DeleteWorkflowRequest()];

declare 'UpdateWorkflowRequest',
    as InstanceOf['Google::Cloud::Workflows::V1beta::Workflows::UpdateWorkflowRequest'];

coerce 'UpdateWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Workflows::V1beta::Workflows::UpdateWorkflowRequest'->new($_) };

declare 'RepeatedUpdateWorkflowRequest',
    as ArrayRef[UpdateWorkflowRequest()];

coerce 'RepeatedUpdateWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1beta::Workflows::UpdateWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkflowRequest',
    as HashRef[UpdateWorkflowRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Workflows::V1beta::Workflows::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Workflows::V1beta::Workflows::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::V1beta::Workflows::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Workflows::V1beta::Workflows::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
