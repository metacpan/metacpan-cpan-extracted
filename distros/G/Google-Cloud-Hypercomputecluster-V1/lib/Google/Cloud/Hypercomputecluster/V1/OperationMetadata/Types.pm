package Google::Cloud::Hypercomputecluster::V1::OperationMetadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'OperationProgress',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationProgress'];

coerce 'OperationProgress',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationProgress'->new($_) };

declare 'RepeatedOperationProgress',
    as ArrayRef[OperationProgress()];

coerce 'RepeatedOperationProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationProgress'->new($_) } @$_ ] };

declare 'MapStringOperationProgress',
    as HashRef[OperationProgress()];

declare 'OperationStep',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationStep'];

coerce 'OperationStep',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationStep'->new($_) };

declare 'RepeatedOperationStep',
    as ArrayRef[OperationStep()];

coerce 'RepeatedOperationStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationStep'->new($_) } @$_ ] };

declare 'MapStringOperationStep',
    as HashRef[OperationStep()];

declare 'State',
    as (Int | Str);

declare 'CreateNetwork',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNetwork'];

coerce 'CreateNetwork',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNetwork'->new($_) };

declare 'RepeatedCreateNetwork',
    as ArrayRef[CreateNetwork()];

coerce 'RepeatedCreateNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNetwork'->new($_) } @$_ ] };

declare 'MapStringCreateNetwork',
    as HashRef[CreateNetwork()];

declare 'CreatePrivateServiceAccess',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePrivateServiceAccess'];

coerce 'CreatePrivateServiceAccess',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePrivateServiceAccess'->new($_) };

declare 'RepeatedCreatePrivateServiceAccess',
    as ArrayRef[CreatePrivateServiceAccess()];

coerce 'RepeatedCreatePrivateServiceAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePrivateServiceAccess'->new($_) } @$_ ] };

declare 'MapStringCreatePrivateServiceAccess',
    as HashRef[CreatePrivateServiceAccess()];

declare 'CreateFilestoreInstance',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateFilestoreInstance'];

coerce 'CreateFilestoreInstance',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateFilestoreInstance'->new($_) };

declare 'RepeatedCreateFilestoreInstance',
    as ArrayRef[CreateFilestoreInstance()];

coerce 'RepeatedCreateFilestoreInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateFilestoreInstance'->new($_) } @$_ ] };

declare 'MapStringCreateFilestoreInstance',
    as HashRef[CreateFilestoreInstance()];

declare 'CreateStorageBucket',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateStorageBucket'];

coerce 'CreateStorageBucket',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateStorageBucket'->new($_) };

declare 'RepeatedCreateStorageBucket',
    as ArrayRef[CreateStorageBucket()];

coerce 'RepeatedCreateStorageBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateStorageBucket'->new($_) } @$_ ] };

declare 'MapStringCreateStorageBucket',
    as HashRef[CreateStorageBucket()];

declare 'CreateLustreInstance',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLustreInstance'];

coerce 'CreateLustreInstance',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLustreInstance'->new($_) };

declare 'RepeatedCreateLustreInstance',
    as ArrayRef[CreateLustreInstance()];

coerce 'RepeatedCreateLustreInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLustreInstance'->new($_) } @$_ ] };

declare 'MapStringCreateLustreInstance',
    as HashRef[CreateLustreInstance()];

declare 'CreateOrchestrator',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateOrchestrator'];

coerce 'CreateOrchestrator',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateOrchestrator'->new($_) };

declare 'RepeatedCreateOrchestrator',
    as ArrayRef[CreateOrchestrator()];

coerce 'RepeatedCreateOrchestrator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateOrchestrator'->new($_) } @$_ ] };

declare 'MapStringCreateOrchestrator',
    as HashRef[CreateOrchestrator()];

declare 'CreateNodeset',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNodeset'];

coerce 'CreateNodeset',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNodeset'->new($_) };

declare 'RepeatedCreateNodeset',
    as ArrayRef[CreateNodeset()];

coerce 'RepeatedCreateNodeset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNodeset'->new($_) } @$_ ] };

declare 'MapStringCreateNodeset',
    as HashRef[CreateNodeset()];

declare 'CreatePartition',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePartition'];

coerce 'CreatePartition',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePartition'->new($_) };

declare 'RepeatedCreatePartition',
    as ArrayRef[CreatePartition()];

coerce 'RepeatedCreatePartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePartition'->new($_) } @$_ ] };

declare 'MapStringCreatePartition',
    as HashRef[CreatePartition()];

declare 'CreateLoginNode',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLoginNode'];

coerce 'CreateLoginNode',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLoginNode'->new($_) };

declare 'RepeatedCreateLoginNode',
    as ArrayRef[CreateLoginNode()];

coerce 'RepeatedCreateLoginNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLoginNode'->new($_) } @$_ ] };

declare 'MapStringCreateLoginNode',
    as HashRef[CreateLoginNode()];

declare 'CheckClusterHealth',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CheckClusterHealth'];

coerce 'CheckClusterHealth',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CheckClusterHealth'->new($_) };

declare 'RepeatedCheckClusterHealth',
    as ArrayRef[CheckClusterHealth()];

coerce 'RepeatedCheckClusterHealth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CheckClusterHealth'->new($_) } @$_ ] };

declare 'MapStringCheckClusterHealth',
    as HashRef[CheckClusterHealth()];

declare 'UpdateOrchestrator',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateOrchestrator'];

coerce 'UpdateOrchestrator',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateOrchestrator'->new($_) };

declare 'RepeatedUpdateOrchestrator',
    as ArrayRef[UpdateOrchestrator()];

coerce 'RepeatedUpdateOrchestrator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateOrchestrator'->new($_) } @$_ ] };

declare 'MapStringUpdateOrchestrator',
    as HashRef[UpdateOrchestrator()];

declare 'UpdateNodeset',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateNodeset'];

coerce 'UpdateNodeset',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateNodeset'->new($_) };

declare 'RepeatedUpdateNodeset',
    as ArrayRef[UpdateNodeset()];

coerce 'RepeatedUpdateNodeset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateNodeset'->new($_) } @$_ ] };

declare 'MapStringUpdateNodeset',
    as HashRef[UpdateNodeset()];

declare 'UpdatePartition',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdatePartition'];

coerce 'UpdatePartition',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdatePartition'->new($_) };

declare 'RepeatedUpdatePartition',
    as ArrayRef[UpdatePartition()];

coerce 'RepeatedUpdatePartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdatePartition'->new($_) } @$_ ] };

declare 'MapStringUpdatePartition',
    as HashRef[UpdatePartition()];

declare 'UpdateLoginNode',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateLoginNode'];

coerce 'UpdateLoginNode',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateLoginNode'->new($_) };

declare 'RepeatedUpdateLoginNode',
    as ArrayRef[UpdateLoginNode()];

coerce 'RepeatedUpdateLoginNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateLoginNode'->new($_) } @$_ ] };

declare 'MapStringUpdateLoginNode',
    as HashRef[UpdateLoginNode()];

declare 'DeleteOrchestrator',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteOrchestrator'];

coerce 'DeleteOrchestrator',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteOrchestrator'->new($_) };

declare 'RepeatedDeleteOrchestrator',
    as ArrayRef[DeleteOrchestrator()];

coerce 'RepeatedDeleteOrchestrator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteOrchestrator'->new($_) } @$_ ] };

declare 'MapStringDeleteOrchestrator',
    as HashRef[DeleteOrchestrator()];

declare 'DeleteNodeset',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNodeset'];

coerce 'DeleteNodeset',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNodeset'->new($_) };

declare 'RepeatedDeleteNodeset',
    as ArrayRef[DeleteNodeset()];

coerce 'RepeatedDeleteNodeset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNodeset'->new($_) } @$_ ] };

declare 'MapStringDeleteNodeset',
    as HashRef[DeleteNodeset()];

declare 'DeletePartition',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePartition'];

coerce 'DeletePartition',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePartition'->new($_) };

declare 'RepeatedDeletePartition',
    as ArrayRef[DeletePartition()];

coerce 'RepeatedDeletePartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePartition'->new($_) } @$_ ] };

declare 'MapStringDeletePartition',
    as HashRef[DeletePartition()];

declare 'DeleteLoginNode',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLoginNode'];

coerce 'DeleteLoginNode',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLoginNode'->new($_) };

declare 'RepeatedDeleteLoginNode',
    as ArrayRef[DeleteLoginNode()];

coerce 'RepeatedDeleteLoginNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLoginNode'->new($_) } @$_ ] };

declare 'MapStringDeleteLoginNode',
    as HashRef[DeleteLoginNode()];

declare 'DeleteFilestoreInstance',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteFilestoreInstance'];

coerce 'DeleteFilestoreInstance',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteFilestoreInstance'->new($_) };

declare 'RepeatedDeleteFilestoreInstance',
    as ArrayRef[DeleteFilestoreInstance()];

coerce 'RepeatedDeleteFilestoreInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteFilestoreInstance'->new($_) } @$_ ] };

declare 'MapStringDeleteFilestoreInstance',
    as HashRef[DeleteFilestoreInstance()];

declare 'DeleteStorageBucket',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteStorageBucket'];

coerce 'DeleteStorageBucket',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteStorageBucket'->new($_) };

declare 'RepeatedDeleteStorageBucket',
    as ArrayRef[DeleteStorageBucket()];

coerce 'RepeatedDeleteStorageBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteStorageBucket'->new($_) } @$_ ] };

declare 'MapStringDeleteStorageBucket',
    as HashRef[DeleteStorageBucket()];

declare 'DeleteLustreInstance',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLustreInstance'];

coerce 'DeleteLustreInstance',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLustreInstance'->new($_) };

declare 'RepeatedDeleteLustreInstance',
    as ArrayRef[DeleteLustreInstance()];

coerce 'RepeatedDeleteLustreInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLustreInstance'->new($_) } @$_ ] };

declare 'MapStringDeleteLustreInstance',
    as HashRef[DeleteLustreInstance()];

declare 'DeletePrivateServiceAccess',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePrivateServiceAccess'];

coerce 'DeletePrivateServiceAccess',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePrivateServiceAccess'->new($_) };

declare 'RepeatedDeletePrivateServiceAccess',
    as ArrayRef[DeletePrivateServiceAccess()];

coerce 'RepeatedDeletePrivateServiceAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePrivateServiceAccess'->new($_) } @$_ ] };

declare 'MapStringDeletePrivateServiceAccess',
    as HashRef[DeletePrivateServiceAccess()];

declare 'DeleteNetwork',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNetwork'];

coerce 'DeleteNetwork',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNetwork'->new($_) };

declare 'RepeatedDeleteNetwork',
    as ArrayRef[DeleteNetwork()];

coerce 'RepeatedDeleteNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNetwork'->new($_) } @$_ ] };

declare 'MapStringDeleteNetwork',
    as HashRef[DeleteNetwork()];

1;

__END__

=head1 NAME

Google::Cloud::Hypercomputecluster::V1::OperationMetadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
