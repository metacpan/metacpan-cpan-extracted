package Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BlockchainNode',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode'];

coerce 'BlockchainNode',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode'->new($_) };

declare 'RepeatedBlockchainNode',
    as ArrayRef[BlockchainNode()];

coerce 'RepeatedBlockchainNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode'->new($_) } @$_ ] };

declare 'MapStringBlockchainNode',
    as HashRef[BlockchainNode()];

declare 'BlockchainType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'ConnectionInfo',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::ConnectionInfo'];

coerce 'ConnectionInfo',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::ConnectionInfo'->new($_) };

declare 'RepeatedConnectionInfo',
    as ArrayRef[ConnectionInfo()];

coerce 'RepeatedConnectionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::ConnectionInfo'->new($_) } @$_ ] };

declare 'MapStringConnectionInfo',
    as HashRef[ConnectionInfo()];

declare 'EndpointInfo',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::ConnectionInfo::EndpointInfo'];

coerce 'EndpointInfo',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::ConnectionInfo::EndpointInfo'->new($_) };

declare 'RepeatedEndpointInfo',
    as ArrayRef[EndpointInfo()];

coerce 'RepeatedEndpointInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::ConnectionInfo::EndpointInfo'->new($_) } @$_ ] };

declare 'MapStringEndpointInfo',
    as HashRef[EndpointInfo()];

declare 'EthereumDetails',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails'];

coerce 'EthereumDetails',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails'->new($_) };

declare 'RepeatedEthereumDetails',
    as ArrayRef[EthereumDetails()];

coerce 'RepeatedEthereumDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails'->new($_) } @$_ ] };

declare 'MapStringEthereumDetails',
    as HashRef[EthereumDetails()];

declare 'Network',
    as (Int | Str);

declare 'NodeType',
    as (Int | Str);

declare 'ExecutionClient',
    as (Int | Str);

declare 'ConsensusClient',
    as (Int | Str);

declare 'GethDetails',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails::GethDetails'];

coerce 'GethDetails',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails::GethDetails'->new($_) };

declare 'RepeatedGethDetails',
    as ArrayRef[GethDetails()];

coerce 'RepeatedGethDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails::GethDetails'->new($_) } @$_ ] };

declare 'MapStringGethDetails',
    as HashRef[GethDetails()];

declare 'GarbageCollectionMode',
    as (Int | Str);

declare 'EthereumEndpoints',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails::EthereumEndpoints'];

coerce 'EthereumEndpoints',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails::EthereumEndpoints'->new($_) };

declare 'RepeatedEthereumEndpoints',
    as ArrayRef[EthereumEndpoints()];

coerce 'RepeatedEthereumEndpoints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails::EthereumEndpoints'->new($_) } @$_ ] };

declare 'MapStringEthereumEndpoints',
    as HashRef[EthereumEndpoints()];

declare 'ValidatorConfig',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails::ValidatorConfig'];

coerce 'ValidatorConfig',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails::ValidatorConfig'->new($_) };

declare 'RepeatedValidatorConfig',
    as ArrayRef[ValidatorConfig()];

coerce 'RepeatedValidatorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::EthereumDetails::ValidatorConfig'->new($_) } @$_ ] };

declare 'MapStringValidatorConfig',
    as HashRef[ValidatorConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::BlockchainNode::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListBlockchainNodesRequest',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::ListBlockchainNodesRequest'];

coerce 'ListBlockchainNodesRequest',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::ListBlockchainNodesRequest'->new($_) };

declare 'RepeatedListBlockchainNodesRequest',
    as ArrayRef[ListBlockchainNodesRequest()];

coerce 'RepeatedListBlockchainNodesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::ListBlockchainNodesRequest'->new($_) } @$_ ] };

declare 'MapStringListBlockchainNodesRequest',
    as HashRef[ListBlockchainNodesRequest()];

declare 'ListBlockchainNodesResponse',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::ListBlockchainNodesResponse'];

coerce 'ListBlockchainNodesResponse',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::ListBlockchainNodesResponse'->new($_) };

declare 'RepeatedListBlockchainNodesResponse',
    as ArrayRef[ListBlockchainNodesResponse()];

coerce 'RepeatedListBlockchainNodesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::ListBlockchainNodesResponse'->new($_) } @$_ ] };

declare 'MapStringListBlockchainNodesResponse',
    as HashRef[ListBlockchainNodesResponse()];

declare 'GetBlockchainNodeRequest',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::GetBlockchainNodeRequest'];

coerce 'GetBlockchainNodeRequest',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::GetBlockchainNodeRequest'->new($_) };

declare 'RepeatedGetBlockchainNodeRequest',
    as ArrayRef[GetBlockchainNodeRequest()];

coerce 'RepeatedGetBlockchainNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::GetBlockchainNodeRequest'->new($_) } @$_ ] };

declare 'MapStringGetBlockchainNodeRequest',
    as HashRef[GetBlockchainNodeRequest()];

declare 'CreateBlockchainNodeRequest',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::CreateBlockchainNodeRequest'];

coerce 'CreateBlockchainNodeRequest',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::CreateBlockchainNodeRequest'->new($_) };

declare 'RepeatedCreateBlockchainNodeRequest',
    as ArrayRef[CreateBlockchainNodeRequest()];

coerce 'RepeatedCreateBlockchainNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::CreateBlockchainNodeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBlockchainNodeRequest',
    as HashRef[CreateBlockchainNodeRequest()];

declare 'UpdateBlockchainNodeRequest',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::UpdateBlockchainNodeRequest'];

coerce 'UpdateBlockchainNodeRequest',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::UpdateBlockchainNodeRequest'->new($_) };

declare 'RepeatedUpdateBlockchainNodeRequest',
    as ArrayRef[UpdateBlockchainNodeRequest()];

coerce 'RepeatedUpdateBlockchainNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::UpdateBlockchainNodeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBlockchainNodeRequest',
    as HashRef[UpdateBlockchainNodeRequest()];

declare 'DeleteBlockchainNodeRequest',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::DeleteBlockchainNodeRequest'];

coerce 'DeleteBlockchainNodeRequest',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::DeleteBlockchainNodeRequest'->new($_) };

declare 'RepeatedDeleteBlockchainNodeRequest',
    as ArrayRef[DeleteBlockchainNodeRequest()];

coerce 'RepeatedDeleteBlockchainNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::DeleteBlockchainNodeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBlockchainNodeRequest',
    as HashRef[DeleteBlockchainNodeRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Blockchainnodeengine::V1::Blockchainnodeengine::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
