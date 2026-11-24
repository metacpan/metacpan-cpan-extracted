package Google::Partner::Aistreams::V1alpha1::Aistreams::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Cluster',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'LabelsEntry',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::Cluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::Cluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::Cluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListClustersRequest',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'Stream',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::Stream'];

coerce 'Stream',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::Stream'->new($_) };

declare 'RepeatedStream',
    as ArrayRef[Stream()];

coerce 'RepeatedStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::Stream'->new($_) } @$_ ] };

declare 'MapStringStream',
    as HashRef[Stream()];

declare 'LabelsEntry',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::Stream::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::Stream::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::Stream::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListStreamsRequest',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::ListStreamsRequest'];

coerce 'ListStreamsRequest',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::ListStreamsRequest'->new($_) };

declare 'RepeatedListStreamsRequest',
    as ArrayRef[ListStreamsRequest()];

coerce 'RepeatedListStreamsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::ListStreamsRequest'->new($_) } @$_ ] };

declare 'MapStringListStreamsRequest',
    as HashRef[ListStreamsRequest()];

declare 'ListStreamsResponse',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::ListStreamsResponse'];

coerce 'ListStreamsResponse',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::ListStreamsResponse'->new($_) };

declare 'RepeatedListStreamsResponse',
    as ArrayRef[ListStreamsResponse()];

coerce 'RepeatedListStreamsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::ListStreamsResponse'->new($_) } @$_ ] };

declare 'MapStringListStreamsResponse',
    as HashRef[ListStreamsResponse()];

declare 'GetStreamRequest',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::GetStreamRequest'];

coerce 'GetStreamRequest',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::GetStreamRequest'->new($_) };

declare 'RepeatedGetStreamRequest',
    as ArrayRef[GetStreamRequest()];

coerce 'RepeatedGetStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::GetStreamRequest'->new($_) } @$_ ] };

declare 'MapStringGetStreamRequest',
    as HashRef[GetStreamRequest()];

declare 'CreateStreamRequest',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::CreateStreamRequest'];

coerce 'CreateStreamRequest',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::CreateStreamRequest'->new($_) };

declare 'RepeatedCreateStreamRequest',
    as ArrayRef[CreateStreamRequest()];

coerce 'RepeatedCreateStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::CreateStreamRequest'->new($_) } @$_ ] };

declare 'MapStringCreateStreamRequest',
    as HashRef[CreateStreamRequest()];

declare 'UpdateStreamRequest',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::UpdateStreamRequest'];

coerce 'UpdateStreamRequest',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::UpdateStreamRequest'->new($_) };

declare 'RepeatedUpdateStreamRequest',
    as ArrayRef[UpdateStreamRequest()];

coerce 'RepeatedUpdateStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::UpdateStreamRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateStreamRequest',
    as HashRef[UpdateStreamRequest()];

declare 'DeleteStreamRequest',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::DeleteStreamRequest'];

coerce 'DeleteStreamRequest',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::DeleteStreamRequest'->new($_) };

declare 'RepeatedDeleteStreamRequest',
    as ArrayRef[DeleteStreamRequest()];

coerce 'RepeatedDeleteStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::DeleteStreamRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteStreamRequest',
    as HashRef[DeleteStreamRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Partner::Aistreams::V1alpha1::Aistreams::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Partner::Aistreams::V1alpha1::Aistreams::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Partner::Aistreams::V1alpha1::Aistreams::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Partner::Aistreams::V1alpha1::Aistreams::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
