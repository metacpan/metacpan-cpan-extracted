package Google::Cloud::Visionai::V1alpha1::StreamingResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GstreamerBufferDescriptor',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamingResources::GstreamerBufferDescriptor'];

coerce 'GstreamerBufferDescriptor',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::GstreamerBufferDescriptor'->new($_) };

declare 'RepeatedGstreamerBufferDescriptor',
    as ArrayRef[GstreamerBufferDescriptor()];

coerce 'RepeatedGstreamerBufferDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::GstreamerBufferDescriptor'->new($_) } @$_ ] };

declare 'MapStringGstreamerBufferDescriptor',
    as HashRef[GstreamerBufferDescriptor()];

declare 'RawImageDescriptor',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamingResources::RawImageDescriptor'];

coerce 'RawImageDescriptor',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::RawImageDescriptor'->new($_) };

declare 'RepeatedRawImageDescriptor',
    as ArrayRef[RawImageDescriptor()];

coerce 'RepeatedRawImageDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::RawImageDescriptor'->new($_) } @$_ ] };

declare 'MapStringRawImageDescriptor',
    as HashRef[RawImageDescriptor()];

declare 'PacketType',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketType'];

coerce 'PacketType',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketType'->new($_) };

declare 'RepeatedPacketType',
    as ArrayRef[PacketType()];

coerce 'RepeatedPacketType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketType'->new($_) } @$_ ] };

declare 'MapStringPacketType',
    as HashRef[PacketType()];

declare 'TypeDescriptor',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketType::TypeDescriptor'];

coerce 'TypeDescriptor',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketType::TypeDescriptor'->new($_) };

declare 'RepeatedTypeDescriptor',
    as ArrayRef[TypeDescriptor()];

coerce 'RepeatedTypeDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketType::TypeDescriptor'->new($_) } @$_ ] };

declare 'MapStringTypeDescriptor',
    as HashRef[TypeDescriptor()];

declare 'ServerMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamingResources::ServerMetadata'];

coerce 'ServerMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::ServerMetadata'->new($_) };

declare 'RepeatedServerMetadata',
    as ArrayRef[ServerMetadata()];

coerce 'RepeatedServerMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::ServerMetadata'->new($_) } @$_ ] };

declare 'MapStringServerMetadata',
    as HashRef[ServerMetadata()];

declare 'SeriesMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamingResources::SeriesMetadata'];

coerce 'SeriesMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::SeriesMetadata'->new($_) };

declare 'RepeatedSeriesMetadata',
    as ArrayRef[SeriesMetadata()];

coerce 'RepeatedSeriesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::SeriesMetadata'->new($_) } @$_ ] };

declare 'MapStringSeriesMetadata',
    as HashRef[SeriesMetadata()];

declare 'PacketHeader',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketHeader'];

coerce 'PacketHeader',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketHeader'->new($_) };

declare 'RepeatedPacketHeader',
    as ArrayRef[PacketHeader()];

coerce 'RepeatedPacketHeader',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketHeader'->new($_) } @$_ ] };

declare 'MapStringPacketHeader',
    as HashRef[PacketHeader()];

declare 'Packet',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::StreamingResources::Packet'];

coerce 'Packet',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::Packet'->new($_) };

declare 'RepeatedPacket',
    as ArrayRef[Packet()];

coerce 'RepeatedPacket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::StreamingResources::Packet'->new($_) } @$_ ] };

declare 'MapStringPacket',
    as HashRef[Packet()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1alpha1::StreamingResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
