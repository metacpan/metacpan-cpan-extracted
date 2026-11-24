package Google::Cloud::Netapp::V1::Replication::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TransferStats',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::TransferStats'];

coerce 'TransferStats',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::TransferStats'->new($_) };

declare 'RepeatedTransferStats',
    as ArrayRef[TransferStats()];

coerce 'RepeatedTransferStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::TransferStats'->new($_) } @$_ ] };

declare 'MapStringTransferStats',
    as HashRef[TransferStats()];

declare 'Replication',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::Replication'];

coerce 'Replication',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::Replication'->new($_) };

declare 'RepeatedReplication',
    as ArrayRef[Replication()];

coerce 'RepeatedReplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::Replication'->new($_) } @$_ ] };

declare 'MapStringReplication',
    as HashRef[Replication()];

declare 'State',
    as (Int | Str);

declare 'ReplicationRole',
    as (Int | Str);

declare 'ReplicationSchedule',
    as (Int | Str);

declare 'MirrorState',
    as (Int | Str);

declare 'HybridReplicationType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::Replication::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::Replication::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::Replication::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'HybridPeeringDetails',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::HybridPeeringDetails'];

coerce 'HybridPeeringDetails',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::HybridPeeringDetails'->new($_) };

declare 'RepeatedHybridPeeringDetails',
    as ArrayRef[HybridPeeringDetails()];

coerce 'RepeatedHybridPeeringDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::HybridPeeringDetails'->new($_) } @$_ ] };

declare 'MapStringHybridPeeringDetails',
    as HashRef[HybridPeeringDetails()];

declare 'ListReplicationsRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::ListReplicationsRequest'];

coerce 'ListReplicationsRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::ListReplicationsRequest'->new($_) };

declare 'RepeatedListReplicationsRequest',
    as ArrayRef[ListReplicationsRequest()];

coerce 'RepeatedListReplicationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::ListReplicationsRequest'->new($_) } @$_ ] };

declare 'MapStringListReplicationsRequest',
    as HashRef[ListReplicationsRequest()];

declare 'ListReplicationsResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::ListReplicationsResponse'];

coerce 'ListReplicationsResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::ListReplicationsResponse'->new($_) };

declare 'RepeatedListReplicationsResponse',
    as ArrayRef[ListReplicationsResponse()];

coerce 'RepeatedListReplicationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::ListReplicationsResponse'->new($_) } @$_ ] };

declare 'MapStringListReplicationsResponse',
    as HashRef[ListReplicationsResponse()];

declare 'GetReplicationRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::GetReplicationRequest'];

coerce 'GetReplicationRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::GetReplicationRequest'->new($_) };

declare 'RepeatedGetReplicationRequest',
    as ArrayRef[GetReplicationRequest()];

coerce 'RepeatedGetReplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::GetReplicationRequest'->new($_) } @$_ ] };

declare 'MapStringGetReplicationRequest',
    as HashRef[GetReplicationRequest()];

declare 'DestinationVolumeParameters',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::DestinationVolumeParameters'];

coerce 'DestinationVolumeParameters',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::DestinationVolumeParameters'->new($_) };

declare 'RepeatedDestinationVolumeParameters',
    as ArrayRef[DestinationVolumeParameters()];

coerce 'RepeatedDestinationVolumeParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::DestinationVolumeParameters'->new($_) } @$_ ] };

declare 'MapStringDestinationVolumeParameters',
    as HashRef[DestinationVolumeParameters()];

declare 'CreateReplicationRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::CreateReplicationRequest'];

coerce 'CreateReplicationRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::CreateReplicationRequest'->new($_) };

declare 'RepeatedCreateReplicationRequest',
    as ArrayRef[CreateReplicationRequest()];

coerce 'RepeatedCreateReplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::CreateReplicationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReplicationRequest',
    as HashRef[CreateReplicationRequest()];

declare 'DeleteReplicationRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::DeleteReplicationRequest'];

coerce 'DeleteReplicationRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::DeleteReplicationRequest'->new($_) };

declare 'RepeatedDeleteReplicationRequest',
    as ArrayRef[DeleteReplicationRequest()];

coerce 'RepeatedDeleteReplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::DeleteReplicationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReplicationRequest',
    as HashRef[DeleteReplicationRequest()];

declare 'UpdateReplicationRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::UpdateReplicationRequest'];

coerce 'UpdateReplicationRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::UpdateReplicationRequest'->new($_) };

declare 'RepeatedUpdateReplicationRequest',
    as ArrayRef[UpdateReplicationRequest()];

coerce 'RepeatedUpdateReplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::UpdateReplicationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateReplicationRequest',
    as HashRef[UpdateReplicationRequest()];

declare 'StopReplicationRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::StopReplicationRequest'];

coerce 'StopReplicationRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::StopReplicationRequest'->new($_) };

declare 'RepeatedStopReplicationRequest',
    as ArrayRef[StopReplicationRequest()];

coerce 'RepeatedStopReplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::StopReplicationRequest'->new($_) } @$_ ] };

declare 'MapStringStopReplicationRequest',
    as HashRef[StopReplicationRequest()];

declare 'ResumeReplicationRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::ResumeReplicationRequest'];

coerce 'ResumeReplicationRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::ResumeReplicationRequest'->new($_) };

declare 'RepeatedResumeReplicationRequest',
    as ArrayRef[ResumeReplicationRequest()];

coerce 'RepeatedResumeReplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::ResumeReplicationRequest'->new($_) } @$_ ] };

declare 'MapStringResumeReplicationRequest',
    as HashRef[ResumeReplicationRequest()];

declare 'ReverseReplicationDirectionRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::ReverseReplicationDirectionRequest'];

coerce 'ReverseReplicationDirectionRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::ReverseReplicationDirectionRequest'->new($_) };

declare 'RepeatedReverseReplicationDirectionRequest',
    as ArrayRef[ReverseReplicationDirectionRequest()];

coerce 'RepeatedReverseReplicationDirectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::ReverseReplicationDirectionRequest'->new($_) } @$_ ] };

declare 'MapStringReverseReplicationDirectionRequest',
    as HashRef[ReverseReplicationDirectionRequest()];

declare 'EstablishPeeringRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::EstablishPeeringRequest'];

coerce 'EstablishPeeringRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::EstablishPeeringRequest'->new($_) };

declare 'RepeatedEstablishPeeringRequest',
    as ArrayRef[EstablishPeeringRequest()];

coerce 'RepeatedEstablishPeeringRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::EstablishPeeringRequest'->new($_) } @$_ ] };

declare 'MapStringEstablishPeeringRequest',
    as HashRef[EstablishPeeringRequest()];

declare 'SyncReplicationRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Replication::SyncReplicationRequest'];

coerce 'SyncReplicationRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Replication::SyncReplicationRequest'->new($_) };

declare 'RepeatedSyncReplicationRequest',
    as ArrayRef[SyncReplicationRequest()];

coerce 'RepeatedSyncReplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Replication::SyncReplicationRequest'->new($_) } @$_ ] };

declare 'MapStringSyncReplicationRequest',
    as HashRef[SyncReplicationRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::Replication::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
