package Google::Cloud::Video::Livestream::V1::Outputs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ElementaryStream',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::ElementaryStream'];

coerce 'ElementaryStream',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::ElementaryStream'->new($_) };

declare 'RepeatedElementaryStream',
    as ArrayRef[ElementaryStream()];

coerce 'RepeatedElementaryStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::ElementaryStream'->new($_) } @$_ ] };

declare 'MapStringElementaryStream',
    as HashRef[ElementaryStream()];

declare 'MuxStream',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::MuxStream'];

coerce 'MuxStream',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::MuxStream'->new($_) };

declare 'RepeatedMuxStream',
    as ArrayRef[MuxStream()];

coerce 'RepeatedMuxStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::MuxStream'->new($_) } @$_ ] };

declare 'MapStringMuxStream',
    as HashRef[MuxStream()];

declare 'Manifest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::Manifest'];

coerce 'Manifest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::Manifest'->new($_) };

declare 'RepeatedManifest',
    as ArrayRef[Manifest()];

coerce 'RepeatedManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::Manifest'->new($_) } @$_ ] };

declare 'MapStringManifest',
    as HashRef[Manifest()];

declare 'ManifestType',
    as (Int | Str);

declare 'DistributionStream',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::DistributionStream'];

coerce 'DistributionStream',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::DistributionStream'->new($_) };

declare 'RepeatedDistributionStream',
    as ArrayRef[DistributionStream()];

coerce 'RepeatedDistributionStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::DistributionStream'->new($_) } @$_ ] };

declare 'MapStringDistributionStream',
    as HashRef[DistributionStream()];

declare 'Distribution',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::Distribution'];

coerce 'Distribution',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::Distribution'->new($_) };

declare 'RepeatedDistribution',
    as ArrayRef[Distribution()];

coerce 'RepeatedDistribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::Distribution'->new($_) } @$_ ] };

declare 'MapStringDistribution',
    as HashRef[Distribution()];

declare 'State',
    as (Int | Str);

declare 'SrtPushOutputEndpoint',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::SrtPushOutputEndpoint'];

coerce 'SrtPushOutputEndpoint',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::SrtPushOutputEndpoint'->new($_) };

declare 'RepeatedSrtPushOutputEndpoint',
    as ArrayRef[SrtPushOutputEndpoint()];

coerce 'RepeatedSrtPushOutputEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::SrtPushOutputEndpoint'->new($_) } @$_ ] };

declare 'MapStringSrtPushOutputEndpoint',
    as HashRef[SrtPushOutputEndpoint()];

declare 'RtmpPushOutputEndpoint',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::RtmpPushOutputEndpoint'];

coerce 'RtmpPushOutputEndpoint',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::RtmpPushOutputEndpoint'->new($_) };

declare 'RepeatedRtmpPushOutputEndpoint',
    as ArrayRef[RtmpPushOutputEndpoint()];

coerce 'RepeatedRtmpPushOutputEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::RtmpPushOutputEndpoint'->new($_) } @$_ ] };

declare 'MapStringRtmpPushOutputEndpoint',
    as HashRef[RtmpPushOutputEndpoint()];

declare 'SpriteSheet',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::SpriteSheet'];

coerce 'SpriteSheet',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::SpriteSheet'->new($_) };

declare 'RepeatedSpriteSheet',
    as ArrayRef[SpriteSheet()];

coerce 'RepeatedSpriteSheet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::SpriteSheet'->new($_) } @$_ ] };

declare 'MapStringSpriteSheet',
    as HashRef[SpriteSheet()];

declare 'PreprocessingConfig',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig'];

coerce 'PreprocessingConfig',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig'->new($_) };

declare 'RepeatedPreprocessingConfig',
    as ArrayRef[PreprocessingConfig()];

coerce 'RepeatedPreprocessingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig'->new($_) } @$_ ] };

declare 'MapStringPreprocessingConfig',
    as HashRef[PreprocessingConfig()];

declare 'Audio',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig::Audio'];

coerce 'Audio',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig::Audio'->new($_) };

declare 'RepeatedAudio',
    as ArrayRef[Audio()];

coerce 'RepeatedAudio',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig::Audio'->new($_) } @$_ ] };

declare 'MapStringAudio',
    as HashRef[Audio()];

declare 'Crop',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig::Crop'];

coerce 'Crop',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig::Crop'->new($_) };

declare 'RepeatedCrop',
    as ArrayRef[Crop()];

coerce 'RepeatedCrop',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig::Crop'->new($_) } @$_ ] };

declare 'MapStringCrop',
    as HashRef[Crop()];

declare 'Pad',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig::Pad'];

coerce 'Pad',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig::Pad'->new($_) };

declare 'RepeatedPad',
    as ArrayRef[Pad()];

coerce 'RepeatedPad',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::PreprocessingConfig::Pad'->new($_) } @$_ ] };

declare 'MapStringPad',
    as HashRef[Pad()];

declare 'VideoStream',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::VideoStream'];

coerce 'VideoStream',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::VideoStream'->new($_) };

declare 'RepeatedVideoStream',
    as ArrayRef[VideoStream()];

coerce 'RepeatedVideoStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::VideoStream'->new($_) } @$_ ] };

declare 'MapStringVideoStream',
    as HashRef[VideoStream()];

declare 'H264CodecSettings',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::VideoStream::H264CodecSettings'];

coerce 'H264CodecSettings',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::VideoStream::H264CodecSettings'->new($_) };

declare 'RepeatedH264CodecSettings',
    as ArrayRef[H264CodecSettings()];

coerce 'RepeatedH264CodecSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::VideoStream::H264CodecSettings'->new($_) } @$_ ] };

declare 'MapStringH264CodecSettings',
    as HashRef[H264CodecSettings()];

declare 'H265CodecSettings',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::VideoStream::H265CodecSettings'];

coerce 'H265CodecSettings',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::VideoStream::H265CodecSettings'->new($_) };

declare 'RepeatedH265CodecSettings',
    as ArrayRef[H265CodecSettings()];

coerce 'RepeatedH265CodecSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::VideoStream::H265CodecSettings'->new($_) } @$_ ] };

declare 'MapStringH265CodecSettings',
    as HashRef[H265CodecSettings()];

declare 'AudioStream',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::AudioStream'];

coerce 'AudioStream',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::AudioStream'->new($_) };

declare 'RepeatedAudioStream',
    as ArrayRef[AudioStream()];

coerce 'RepeatedAudioStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::AudioStream'->new($_) } @$_ ] };

declare 'MapStringAudioStream',
    as HashRef[AudioStream()];

declare 'AudioMapping',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::AudioStream::AudioMapping'];

coerce 'AudioMapping',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::AudioStream::AudioMapping'->new($_) };

declare 'RepeatedAudioMapping',
    as ArrayRef[AudioMapping()];

coerce 'RepeatedAudioMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::AudioStream::AudioMapping'->new($_) } @$_ ] };

declare 'MapStringAudioMapping',
    as HashRef[AudioMapping()];

declare 'TextStream',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::TextStream'];

coerce 'TextStream',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::TextStream'->new($_) };

declare 'RepeatedTextStream',
    as ArrayRef[TextStream()];

coerce 'RepeatedTextStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::TextStream'->new($_) } @$_ ] };

declare 'MapStringTextStream',
    as HashRef[TextStream()];

declare 'TextMapping',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::TextStream::TextMapping'];

coerce 'TextMapping',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::TextStream::TextMapping'->new($_) };

declare 'RepeatedTextMapping',
    as ArrayRef[TextMapping()];

coerce 'RepeatedTextMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::TextStream::TextMapping'->new($_) } @$_ ] };

declare 'MapStringTextMapping',
    as HashRef[TextMapping()];

declare 'SegmentSettings',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::SegmentSettings'];

coerce 'SegmentSettings',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::SegmentSettings'->new($_) };

declare 'RepeatedSegmentSettings',
    as ArrayRef[SegmentSettings()];

coerce 'RepeatedSegmentSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::SegmentSettings'->new($_) } @$_ ] };

declare 'MapStringSegmentSettings',
    as HashRef[SegmentSettings()];

declare 'TimecodeConfig',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Outputs::TimecodeConfig'];

coerce 'TimecodeConfig',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Outputs::TimecodeConfig'->new($_) };

declare 'RepeatedTimecodeConfig',
    as ArrayRef[TimecodeConfig()];

coerce 'RepeatedTimecodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Outputs::TimecodeConfig'->new($_) } @$_ ] };

declare 'MapStringTimecodeConfig',
    as HashRef[TimecodeConfig()];

declare 'TimecodeSource',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Video::Livestream::V1::Outputs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
