package Google::Cloud::Dataproc::V1::WorkflowTemplates::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WorkflowTemplate',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate'];

coerce 'WorkflowTemplate',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate'->new($_) };

declare 'RepeatedWorkflowTemplate',
    as ArrayRef[WorkflowTemplate()];

coerce 'RepeatedWorkflowTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate'->new($_) } @$_ ] };

declare 'MapStringWorkflowTemplate',
    as HashRef[WorkflowTemplate()];

declare 'EncryptionConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplate::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'WorkflowTemplatePlacement',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplatePlacement'];

coerce 'WorkflowTemplatePlacement',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplatePlacement'->new($_) };

declare 'RepeatedWorkflowTemplatePlacement',
    as ArrayRef[WorkflowTemplatePlacement()];

coerce 'RepeatedWorkflowTemplatePlacement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowTemplatePlacement'->new($_) } @$_ ] };

declare 'MapStringWorkflowTemplatePlacement',
    as HashRef[WorkflowTemplatePlacement()];

declare 'ManagedCluster',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::ManagedCluster'];

coerce 'ManagedCluster',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ManagedCluster'->new($_) };

declare 'RepeatedManagedCluster',
    as ArrayRef[ManagedCluster()];

coerce 'RepeatedManagedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ManagedCluster'->new($_) } @$_ ] };

declare 'MapStringManagedCluster',
    as HashRef[ManagedCluster()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::ManagedCluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ManagedCluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ManagedCluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ClusterSelector',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::ClusterSelector'];

coerce 'ClusterSelector',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ClusterSelector'->new($_) };

declare 'RepeatedClusterSelector',
    as ArrayRef[ClusterSelector()];

coerce 'RepeatedClusterSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ClusterSelector'->new($_) } @$_ ] };

declare 'MapStringClusterSelector',
    as HashRef[ClusterSelector()];

declare 'ClusterLabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::ClusterSelector::ClusterLabelsEntry'];

coerce 'ClusterLabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ClusterSelector::ClusterLabelsEntry'->new($_) };

declare 'RepeatedClusterLabelsEntry',
    as ArrayRef[ClusterLabelsEntry()];

coerce 'RepeatedClusterLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ClusterSelector::ClusterLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringClusterLabelsEntry',
    as HashRef[ClusterLabelsEntry()];

declare 'OrderedJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::OrderedJob'];

coerce 'OrderedJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::OrderedJob'->new($_) };

declare 'RepeatedOrderedJob',
    as ArrayRef[OrderedJob()];

coerce 'RepeatedOrderedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::OrderedJob'->new($_) } @$_ ] };

declare 'MapStringOrderedJob',
    as HashRef[OrderedJob()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::OrderedJob::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::OrderedJob::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::OrderedJob::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TemplateParameter',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::TemplateParameter'];

coerce 'TemplateParameter',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::TemplateParameter'->new($_) };

declare 'RepeatedTemplateParameter',
    as ArrayRef[TemplateParameter()];

coerce 'RepeatedTemplateParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::TemplateParameter'->new($_) } @$_ ] };

declare 'MapStringTemplateParameter',
    as HashRef[TemplateParameter()];

declare 'ParameterValidation',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::ParameterValidation'];

coerce 'ParameterValidation',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ParameterValidation'->new($_) };

declare 'RepeatedParameterValidation',
    as ArrayRef[ParameterValidation()];

coerce 'RepeatedParameterValidation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ParameterValidation'->new($_) } @$_ ] };

declare 'MapStringParameterValidation',
    as HashRef[ParameterValidation()];

declare 'RegexValidation',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::RegexValidation'];

coerce 'RegexValidation',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::RegexValidation'->new($_) };

declare 'RepeatedRegexValidation',
    as ArrayRef[RegexValidation()];

coerce 'RepeatedRegexValidation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::RegexValidation'->new($_) } @$_ ] };

declare 'MapStringRegexValidation',
    as HashRef[RegexValidation()];

declare 'ValueValidation',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::ValueValidation'];

coerce 'ValueValidation',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ValueValidation'->new($_) };

declare 'RepeatedValueValidation',
    as ArrayRef[ValueValidation()];

coerce 'RepeatedValueValidation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ValueValidation'->new($_) } @$_ ] };

declare 'MapStringValueValidation',
    as HashRef[ValueValidation()];

declare 'WorkflowMetadata',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowMetadata'];

coerce 'WorkflowMetadata',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowMetadata'->new($_) };

declare 'RepeatedWorkflowMetadata',
    as ArrayRef[WorkflowMetadata()];

coerce 'RepeatedWorkflowMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowMetadata'->new($_) } @$_ ] };

declare 'MapStringWorkflowMetadata',
    as HashRef[WorkflowMetadata()];

declare 'State',
    as (Int | Str);

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowMetadata::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowMetadata::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowMetadata::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'ClusterOperation',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::ClusterOperation'];

coerce 'ClusterOperation',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ClusterOperation'->new($_) };

declare 'RepeatedClusterOperation',
    as ArrayRef[ClusterOperation()];

coerce 'RepeatedClusterOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ClusterOperation'->new($_) } @$_ ] };

declare 'MapStringClusterOperation',
    as HashRef[ClusterOperation()];

declare 'WorkflowGraph',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowGraph'];

coerce 'WorkflowGraph',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowGraph'->new($_) };

declare 'RepeatedWorkflowGraph',
    as ArrayRef[WorkflowGraph()];

coerce 'RepeatedWorkflowGraph',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowGraph'->new($_) } @$_ ] };

declare 'MapStringWorkflowGraph',
    as HashRef[WorkflowGraph()];

declare 'WorkflowNode',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowNode'];

coerce 'WorkflowNode',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowNode'->new($_) };

declare 'RepeatedWorkflowNode',
    as ArrayRef[WorkflowNode()];

coerce 'RepeatedWorkflowNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::WorkflowNode'->new($_) } @$_ ] };

declare 'MapStringWorkflowNode',
    as HashRef[WorkflowNode()];

declare 'NodeState',
    as (Int | Str);

declare 'CreateWorkflowTemplateRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::CreateWorkflowTemplateRequest'];

coerce 'CreateWorkflowTemplateRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::CreateWorkflowTemplateRequest'->new($_) };

declare 'RepeatedCreateWorkflowTemplateRequest',
    as ArrayRef[CreateWorkflowTemplateRequest()];

coerce 'RepeatedCreateWorkflowTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::CreateWorkflowTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkflowTemplateRequest',
    as HashRef[CreateWorkflowTemplateRequest()];

declare 'GetWorkflowTemplateRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::GetWorkflowTemplateRequest'];

coerce 'GetWorkflowTemplateRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::GetWorkflowTemplateRequest'->new($_) };

declare 'RepeatedGetWorkflowTemplateRequest',
    as ArrayRef[GetWorkflowTemplateRequest()];

coerce 'RepeatedGetWorkflowTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::GetWorkflowTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkflowTemplateRequest',
    as HashRef[GetWorkflowTemplateRequest()];

declare 'InstantiateWorkflowTemplateRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::InstantiateWorkflowTemplateRequest'];

coerce 'InstantiateWorkflowTemplateRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::InstantiateWorkflowTemplateRequest'->new($_) };

declare 'RepeatedInstantiateWorkflowTemplateRequest',
    as ArrayRef[InstantiateWorkflowTemplateRequest()];

coerce 'RepeatedInstantiateWorkflowTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::InstantiateWorkflowTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringInstantiateWorkflowTemplateRequest',
    as HashRef[InstantiateWorkflowTemplateRequest()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::InstantiateWorkflowTemplateRequest::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::InstantiateWorkflowTemplateRequest::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::InstantiateWorkflowTemplateRequest::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'InstantiateInlineWorkflowTemplateRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::InstantiateInlineWorkflowTemplateRequest'];

coerce 'InstantiateInlineWorkflowTemplateRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::InstantiateInlineWorkflowTemplateRequest'->new($_) };

declare 'RepeatedInstantiateInlineWorkflowTemplateRequest',
    as ArrayRef[InstantiateInlineWorkflowTemplateRequest()];

coerce 'RepeatedInstantiateInlineWorkflowTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::InstantiateInlineWorkflowTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringInstantiateInlineWorkflowTemplateRequest',
    as HashRef[InstantiateInlineWorkflowTemplateRequest()];

declare 'UpdateWorkflowTemplateRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::UpdateWorkflowTemplateRequest'];

coerce 'UpdateWorkflowTemplateRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::UpdateWorkflowTemplateRequest'->new($_) };

declare 'RepeatedUpdateWorkflowTemplateRequest',
    as ArrayRef[UpdateWorkflowTemplateRequest()];

coerce 'RepeatedUpdateWorkflowTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::UpdateWorkflowTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkflowTemplateRequest',
    as HashRef[UpdateWorkflowTemplateRequest()];

declare 'ListWorkflowTemplatesRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::ListWorkflowTemplatesRequest'];

coerce 'ListWorkflowTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ListWorkflowTemplatesRequest'->new($_) };

declare 'RepeatedListWorkflowTemplatesRequest',
    as ArrayRef[ListWorkflowTemplatesRequest()];

coerce 'RepeatedListWorkflowTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ListWorkflowTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkflowTemplatesRequest',
    as HashRef[ListWorkflowTemplatesRequest()];

declare 'ListWorkflowTemplatesResponse',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::ListWorkflowTemplatesResponse'];

coerce 'ListWorkflowTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ListWorkflowTemplatesResponse'->new($_) };

declare 'RepeatedListWorkflowTemplatesResponse',
    as ArrayRef[ListWorkflowTemplatesResponse()];

coerce 'RepeatedListWorkflowTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::ListWorkflowTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkflowTemplatesResponse',
    as HashRef[ListWorkflowTemplatesResponse()];

declare 'DeleteWorkflowTemplateRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::WorkflowTemplates::DeleteWorkflowTemplateRequest'];

coerce 'DeleteWorkflowTemplateRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::DeleteWorkflowTemplateRequest'->new($_) };

declare 'RepeatedDeleteWorkflowTemplateRequest',
    as ArrayRef[DeleteWorkflowTemplateRequest()];

coerce 'RepeatedDeleteWorkflowTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::WorkflowTemplates::DeleteWorkflowTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkflowTemplateRequest',
    as HashRef[DeleteWorkflowTemplateRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::WorkflowTemplates::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
