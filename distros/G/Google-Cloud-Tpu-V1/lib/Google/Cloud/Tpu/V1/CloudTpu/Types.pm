package Google::Cloud::Tpu::V1::CloudTpu::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SchedulingConfig',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::SchedulingConfig'];

coerce 'SchedulingConfig',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::SchedulingConfig'->new($_) };

declare 'RepeatedSchedulingConfig',
    as ArrayRef[SchedulingConfig()];

coerce 'RepeatedSchedulingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::SchedulingConfig'->new($_) } @$_ ] };

declare 'MapStringSchedulingConfig',
    as HashRef[SchedulingConfig()];

declare 'NetworkEndpoint',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::NetworkEndpoint'];

coerce 'NetworkEndpoint',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::NetworkEndpoint'->new($_) };

declare 'RepeatedNetworkEndpoint',
    as ArrayRef[NetworkEndpoint()];

coerce 'RepeatedNetworkEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::NetworkEndpoint'->new($_) } @$_ ] };

declare 'MapStringNetworkEndpoint',
    as HashRef[NetworkEndpoint()];

declare 'Node',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'State',
    as (Int | Str);

declare 'Health',
    as (Int | Str);

declare 'ApiVersion',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::Node::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::Node::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::Node::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListNodesRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::ListNodesRequest'];

coerce 'ListNodesRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::ListNodesRequest'->new($_) };

declare 'RepeatedListNodesRequest',
    as ArrayRef[ListNodesRequest()];

coerce 'RepeatedListNodesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::ListNodesRequest'->new($_) } @$_ ] };

declare 'MapStringListNodesRequest',
    as HashRef[ListNodesRequest()];

declare 'ListNodesResponse',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::ListNodesResponse'];

coerce 'ListNodesResponse',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::ListNodesResponse'->new($_) };

declare 'RepeatedListNodesResponse',
    as ArrayRef[ListNodesResponse()];

coerce 'RepeatedListNodesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::ListNodesResponse'->new($_) } @$_ ] };

declare 'MapStringListNodesResponse',
    as HashRef[ListNodesResponse()];

declare 'GetNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::GetNodeRequest'];

coerce 'GetNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::GetNodeRequest'->new($_) };

declare 'RepeatedGetNodeRequest',
    as ArrayRef[GetNodeRequest()];

coerce 'RepeatedGetNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::GetNodeRequest'->new($_) } @$_ ] };

declare 'MapStringGetNodeRequest',
    as HashRef[GetNodeRequest()];

declare 'CreateNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::CreateNodeRequest'];

coerce 'CreateNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::CreateNodeRequest'->new($_) };

declare 'RepeatedCreateNodeRequest',
    as ArrayRef[CreateNodeRequest()];

coerce 'RepeatedCreateNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::CreateNodeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNodeRequest',
    as HashRef[CreateNodeRequest()];

declare 'DeleteNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::DeleteNodeRequest'];

coerce 'DeleteNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::DeleteNodeRequest'->new($_) };

declare 'RepeatedDeleteNodeRequest',
    as ArrayRef[DeleteNodeRequest()];

coerce 'RepeatedDeleteNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::DeleteNodeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNodeRequest',
    as HashRef[DeleteNodeRequest()];

declare 'ReimageNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::ReimageNodeRequest'];

coerce 'ReimageNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::ReimageNodeRequest'->new($_) };

declare 'RepeatedReimageNodeRequest',
    as ArrayRef[ReimageNodeRequest()];

coerce 'RepeatedReimageNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::ReimageNodeRequest'->new($_) } @$_ ] };

declare 'MapStringReimageNodeRequest',
    as HashRef[ReimageNodeRequest()];

declare 'StopNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::StopNodeRequest'];

coerce 'StopNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::StopNodeRequest'->new($_) };

declare 'RepeatedStopNodeRequest',
    as ArrayRef[StopNodeRequest()];

coerce 'RepeatedStopNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::StopNodeRequest'->new($_) } @$_ ] };

declare 'MapStringStopNodeRequest',
    as HashRef[StopNodeRequest()];

declare 'StartNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::StartNodeRequest'];

coerce 'StartNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::StartNodeRequest'->new($_) };

declare 'RepeatedStartNodeRequest',
    as ArrayRef[StartNodeRequest()];

coerce 'RepeatedStartNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::StartNodeRequest'->new($_) } @$_ ] };

declare 'MapStringStartNodeRequest',
    as HashRef[StartNodeRequest()];

declare 'TensorFlowVersion',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::TensorFlowVersion'];

coerce 'TensorFlowVersion',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::TensorFlowVersion'->new($_) };

declare 'RepeatedTensorFlowVersion',
    as ArrayRef[TensorFlowVersion()];

coerce 'RepeatedTensorFlowVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::TensorFlowVersion'->new($_) } @$_ ] };

declare 'MapStringTensorFlowVersion',
    as HashRef[TensorFlowVersion()];

declare 'GetTensorFlowVersionRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::GetTensorFlowVersionRequest'];

coerce 'GetTensorFlowVersionRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::GetTensorFlowVersionRequest'->new($_) };

declare 'RepeatedGetTensorFlowVersionRequest',
    as ArrayRef[GetTensorFlowVersionRequest()];

coerce 'RepeatedGetTensorFlowVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::GetTensorFlowVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetTensorFlowVersionRequest',
    as HashRef[GetTensorFlowVersionRequest()];

declare 'ListTensorFlowVersionsRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::ListTensorFlowVersionsRequest'];

coerce 'ListTensorFlowVersionsRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::ListTensorFlowVersionsRequest'->new($_) };

declare 'RepeatedListTensorFlowVersionsRequest',
    as ArrayRef[ListTensorFlowVersionsRequest()];

coerce 'RepeatedListTensorFlowVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::ListTensorFlowVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListTensorFlowVersionsRequest',
    as HashRef[ListTensorFlowVersionsRequest()];

declare 'ListTensorFlowVersionsResponse',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::ListTensorFlowVersionsResponse'];

coerce 'ListTensorFlowVersionsResponse',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::ListTensorFlowVersionsResponse'->new($_) };

declare 'RepeatedListTensorFlowVersionsResponse',
    as ArrayRef[ListTensorFlowVersionsResponse()];

coerce 'RepeatedListTensorFlowVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::ListTensorFlowVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListTensorFlowVersionsResponse',
    as HashRef[ListTensorFlowVersionsResponse()];

declare 'AcceleratorType',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::AcceleratorType'];

coerce 'AcceleratorType',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::AcceleratorType'->new($_) };

declare 'RepeatedAcceleratorType',
    as ArrayRef[AcceleratorType()];

coerce 'RepeatedAcceleratorType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::AcceleratorType'->new($_) } @$_ ] };

declare 'MapStringAcceleratorType',
    as HashRef[AcceleratorType()];

declare 'GetAcceleratorTypeRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::GetAcceleratorTypeRequest'];

coerce 'GetAcceleratorTypeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::GetAcceleratorTypeRequest'->new($_) };

declare 'RepeatedGetAcceleratorTypeRequest',
    as ArrayRef[GetAcceleratorTypeRequest()];

coerce 'RepeatedGetAcceleratorTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::GetAcceleratorTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetAcceleratorTypeRequest',
    as HashRef[GetAcceleratorTypeRequest()];

declare 'ListAcceleratorTypesRequest',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::ListAcceleratorTypesRequest'];

coerce 'ListAcceleratorTypesRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::ListAcceleratorTypesRequest'->new($_) };

declare 'RepeatedListAcceleratorTypesRequest',
    as ArrayRef[ListAcceleratorTypesRequest()];

coerce 'RepeatedListAcceleratorTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::ListAcceleratorTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListAcceleratorTypesRequest',
    as HashRef[ListAcceleratorTypesRequest()];

declare 'ListAcceleratorTypesResponse',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::ListAcceleratorTypesResponse'];

coerce 'ListAcceleratorTypesResponse',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::ListAcceleratorTypesResponse'->new($_) };

declare 'RepeatedListAcceleratorTypesResponse',
    as ArrayRef[ListAcceleratorTypesResponse()];

coerce 'RepeatedListAcceleratorTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::ListAcceleratorTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListAcceleratorTypesResponse',
    as HashRef[ListAcceleratorTypesResponse()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'Symptom',
    as InstanceOf['Google::Cloud::Tpu::V1::CloudTpu::Symptom'];

coerce 'Symptom',
    from HashRef, via { 'Google::Cloud::Tpu::V1::CloudTpu::Symptom'->new($_) };

declare 'RepeatedSymptom',
    as ArrayRef[Symptom()];

coerce 'RepeatedSymptom',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V1::CloudTpu::Symptom'->new($_) } @$_ ] };

declare 'MapStringSymptom',
    as HashRef[Symptom()];

declare 'SymptomType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Tpu::V1::CloudTpu::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
