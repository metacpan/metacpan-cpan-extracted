package Google::Cloud::Video::Transcoder::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Job',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'ProcessingState',
    as (Int | Str);

declare 'ProcessingMode',
    as (Int | Str);

declare 'OptimizationStrategy',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Job::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Job::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Job::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'JobTemplate',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::JobTemplate'];

coerce 'JobTemplate',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::JobTemplate'->new($_) };

declare 'RepeatedJobTemplate',
    as ArrayRef[JobTemplate()];

coerce 'RepeatedJobTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::JobTemplate'->new($_) } @$_ ] };

declare 'MapStringJobTemplate',
    as HashRef[JobTemplate()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::JobTemplate::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::JobTemplate::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::JobTemplate::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'JobConfig',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::JobConfig'];

coerce 'JobConfig',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::JobConfig'->new($_) };

declare 'RepeatedJobConfig',
    as ArrayRef[JobConfig()];

coerce 'RepeatedJobConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::JobConfig'->new($_) } @$_ ] };

declare 'MapStringJobConfig',
    as HashRef[JobConfig()];

declare 'Input',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Input'];

coerce 'Input',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Input'->new($_) };

declare 'RepeatedInput',
    as ArrayRef[Input()];

coerce 'RepeatedInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Input'->new($_) } @$_ ] };

declare 'MapStringInput',
    as HashRef[Input()];

declare 'Output',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Output'];

coerce 'Output',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Output'->new($_) };

declare 'RepeatedOutput',
    as ArrayRef[Output()];

coerce 'RepeatedOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Output'->new($_) } @$_ ] };

declare 'MapStringOutput',
    as HashRef[Output()];

declare 'EditAtom',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::EditAtom'];

coerce 'EditAtom',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::EditAtom'->new($_) };

declare 'RepeatedEditAtom',
    as ArrayRef[EditAtom()];

coerce 'RepeatedEditAtom',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::EditAtom'->new($_) } @$_ ] };

declare 'MapStringEditAtom',
    as HashRef[EditAtom()];

declare 'AdBreak',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::AdBreak'];

coerce 'AdBreak',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::AdBreak'->new($_) };

declare 'RepeatedAdBreak',
    as ArrayRef[AdBreak()];

coerce 'RepeatedAdBreak',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::AdBreak'->new($_) } @$_ ] };

declare 'MapStringAdBreak',
    as HashRef[AdBreak()];

declare 'ElementaryStream',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::ElementaryStream'];

coerce 'ElementaryStream',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::ElementaryStream'->new($_) };

declare 'RepeatedElementaryStream',
    as ArrayRef[ElementaryStream()];

coerce 'RepeatedElementaryStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::ElementaryStream'->new($_) } @$_ ] };

declare 'MapStringElementaryStream',
    as HashRef[ElementaryStream()];

declare 'MuxStream',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::MuxStream'];

coerce 'MuxStream',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::MuxStream'->new($_) };

declare 'RepeatedMuxStream',
    as ArrayRef[MuxStream()];

coerce 'RepeatedMuxStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::MuxStream'->new($_) } @$_ ] };

declare 'MapStringMuxStream',
    as HashRef[MuxStream()];

declare 'Fmp4Config',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::MuxStream::Fmp4Config'];

coerce 'Fmp4Config',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::MuxStream::Fmp4Config'->new($_) };

declare 'RepeatedFmp4Config',
    as ArrayRef[Fmp4Config()];

coerce 'RepeatedFmp4Config',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::MuxStream::Fmp4Config'->new($_) } @$_ ] };

declare 'MapStringFmp4Config',
    as HashRef[Fmp4Config()];

declare 'Manifest',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Manifest'];

coerce 'Manifest',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Manifest'->new($_) };

declare 'RepeatedManifest',
    as ArrayRef[Manifest()];

coerce 'RepeatedManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Manifest'->new($_) } @$_ ] };

declare 'MapStringManifest',
    as HashRef[Manifest()];

declare 'ManifestType',
    as (Int | Str);

declare 'DashConfig',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Manifest::DashConfig'];

coerce 'DashConfig',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Manifest::DashConfig'->new($_) };

declare 'RepeatedDashConfig',
    as ArrayRef[DashConfig()];

coerce 'RepeatedDashConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Manifest::DashConfig'->new($_) } @$_ ] };

declare 'MapStringDashConfig',
    as HashRef[DashConfig()];

declare 'SegmentReferenceScheme',
    as (Int | Str);

declare 'PubsubDestination',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PubsubDestination'];

coerce 'PubsubDestination',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PubsubDestination'->new($_) };

declare 'RepeatedPubsubDestination',
    as ArrayRef[PubsubDestination()];

coerce 'RepeatedPubsubDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PubsubDestination'->new($_) } @$_ ] };

declare 'MapStringPubsubDestination',
    as HashRef[PubsubDestination()];

declare 'SpriteSheet',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::SpriteSheet'];

coerce 'SpriteSheet',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::SpriteSheet'->new($_) };

declare 'RepeatedSpriteSheet',
    as ArrayRef[SpriteSheet()];

coerce 'RepeatedSpriteSheet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::SpriteSheet'->new($_) } @$_ ] };

declare 'MapStringSpriteSheet',
    as HashRef[SpriteSheet()];

declare 'Overlay',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Overlay'];

coerce 'Overlay',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay'->new($_) };

declare 'RepeatedOverlay',
    as ArrayRef[Overlay()];

coerce 'RepeatedOverlay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay'->new($_) } @$_ ] };

declare 'MapStringOverlay',
    as HashRef[Overlay()];

declare 'FadeType',
    as (Int | Str);

declare 'NormalizedCoordinate',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Overlay::NormalizedCoordinate'];

coerce 'NormalizedCoordinate',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::NormalizedCoordinate'->new($_) };

declare 'RepeatedNormalizedCoordinate',
    as ArrayRef[NormalizedCoordinate()];

coerce 'RepeatedNormalizedCoordinate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::NormalizedCoordinate'->new($_) } @$_ ] };

declare 'MapStringNormalizedCoordinate',
    as HashRef[NormalizedCoordinate()];

declare 'Image',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Overlay::Image'];

coerce 'Image',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::Image'->new($_) };

declare 'RepeatedImage',
    as ArrayRef[Image()];

coerce 'RepeatedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::Image'->new($_) } @$_ ] };

declare 'MapStringImage',
    as HashRef[Image()];

declare 'AnimationStatic',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Overlay::AnimationStatic'];

coerce 'AnimationStatic',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::AnimationStatic'->new($_) };

declare 'RepeatedAnimationStatic',
    as ArrayRef[AnimationStatic()];

coerce 'RepeatedAnimationStatic',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::AnimationStatic'->new($_) } @$_ ] };

declare 'MapStringAnimationStatic',
    as HashRef[AnimationStatic()];

declare 'AnimationFade',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Overlay::AnimationFade'];

coerce 'AnimationFade',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::AnimationFade'->new($_) };

declare 'RepeatedAnimationFade',
    as ArrayRef[AnimationFade()];

coerce 'RepeatedAnimationFade',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::AnimationFade'->new($_) } @$_ ] };

declare 'MapStringAnimationFade',
    as HashRef[AnimationFade()];

declare 'AnimationEnd',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Overlay::AnimationEnd'];

coerce 'AnimationEnd',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::AnimationEnd'->new($_) };

declare 'RepeatedAnimationEnd',
    as ArrayRef[AnimationEnd()];

coerce 'RepeatedAnimationEnd',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::AnimationEnd'->new($_) } @$_ ] };

declare 'MapStringAnimationEnd',
    as HashRef[AnimationEnd()];

declare 'Animation',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Overlay::Animation'];

coerce 'Animation',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::Animation'->new($_) };

declare 'RepeatedAnimation',
    as ArrayRef[Animation()];

coerce 'RepeatedAnimation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Overlay::Animation'->new($_) } @$_ ] };

declare 'MapStringAnimation',
    as HashRef[Animation()];

declare 'PreprocessingConfig',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig'];

coerce 'PreprocessingConfig',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig'->new($_) };

declare 'RepeatedPreprocessingConfig',
    as ArrayRef[PreprocessingConfig()];

coerce 'RepeatedPreprocessingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig'->new($_) } @$_ ] };

declare 'MapStringPreprocessingConfig',
    as HashRef[PreprocessingConfig()];

declare 'Color',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Color'];

coerce 'Color',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Color'->new($_) };

declare 'RepeatedColor',
    as ArrayRef[Color()];

coerce 'RepeatedColor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Color'->new($_) } @$_ ] };

declare 'MapStringColor',
    as HashRef[Color()];

declare 'Denoise',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Denoise'];

coerce 'Denoise',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Denoise'->new($_) };

declare 'RepeatedDenoise',
    as ArrayRef[Denoise()];

coerce 'RepeatedDenoise',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Denoise'->new($_) } @$_ ] };

declare 'MapStringDenoise',
    as HashRef[Denoise()];

declare 'Deblock',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deblock'];

coerce 'Deblock',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deblock'->new($_) };

declare 'RepeatedDeblock',
    as ArrayRef[Deblock()];

coerce 'RepeatedDeblock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deblock'->new($_) } @$_ ] };

declare 'MapStringDeblock',
    as HashRef[Deblock()];

declare 'Audio',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Audio'];

coerce 'Audio',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Audio'->new($_) };

declare 'RepeatedAudio',
    as ArrayRef[Audio()];

coerce 'RepeatedAudio',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Audio'->new($_) } @$_ ] };

declare 'MapStringAudio',
    as HashRef[Audio()];

declare 'Crop',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Crop'];

coerce 'Crop',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Crop'->new($_) };

declare 'RepeatedCrop',
    as ArrayRef[Crop()];

coerce 'RepeatedCrop',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Crop'->new($_) } @$_ ] };

declare 'MapStringCrop',
    as HashRef[Crop()];

declare 'Pad',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Pad'];

coerce 'Pad',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Pad'->new($_) };

declare 'RepeatedPad',
    as ArrayRef[Pad()];

coerce 'RepeatedPad',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Pad'->new($_) } @$_ ] };

declare 'MapStringPad',
    as HashRef[Pad()];

declare 'Deinterlace',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deinterlace'];

coerce 'Deinterlace',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deinterlace'->new($_) };

declare 'RepeatedDeinterlace',
    as ArrayRef[Deinterlace()];

coerce 'RepeatedDeinterlace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deinterlace'->new($_) } @$_ ] };

declare 'MapStringDeinterlace',
    as HashRef[Deinterlace()];

declare 'YadifConfig',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deinterlace::YadifConfig'];

coerce 'YadifConfig',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deinterlace::YadifConfig'->new($_) };

declare 'RepeatedYadifConfig',
    as ArrayRef[YadifConfig()];

coerce 'RepeatedYadifConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deinterlace::YadifConfig'->new($_) } @$_ ] };

declare 'MapStringYadifConfig',
    as HashRef[YadifConfig()];

declare 'BwdifConfig',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deinterlace::BwdifConfig'];

coerce 'BwdifConfig',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deinterlace::BwdifConfig'->new($_) };

declare 'RepeatedBwdifConfig',
    as ArrayRef[BwdifConfig()];

coerce 'RepeatedBwdifConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::PreprocessingConfig::Deinterlace::BwdifConfig'->new($_) } @$_ ] };

declare 'MapStringBwdifConfig',
    as HashRef[BwdifConfig()];

declare 'TrackDefinition',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::TrackDefinition'];

coerce 'TrackDefinition',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::TrackDefinition'->new($_) };

declare 'RepeatedTrackDefinition',
    as ArrayRef[TrackDefinition()];

coerce 'RepeatedTrackDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::TrackDefinition'->new($_) } @$_ ] };

declare 'MapStringTrackDefinition',
    as HashRef[TrackDefinition()];

declare 'InputAttributes',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::InputAttributes'];

coerce 'InputAttributes',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::InputAttributes'->new($_) };

declare 'RepeatedInputAttributes',
    as ArrayRef[InputAttributes()];

coerce 'RepeatedInputAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::InputAttributes'->new($_) } @$_ ] };

declare 'MapStringInputAttributes',
    as HashRef[InputAttributes()];

declare 'VideoStream',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream'];

coerce 'VideoStream',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream'->new($_) };

declare 'RepeatedVideoStream',
    as ArrayRef[VideoStream()];

coerce 'RepeatedVideoStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream'->new($_) } @$_ ] };

declare 'MapStringVideoStream',
    as HashRef[VideoStream()];

declare 'FrameRateConversionStrategy',
    as (Int | Str);

declare 'H264ColorFormatSDR',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H264ColorFormatSDR'];

coerce 'H264ColorFormatSDR',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H264ColorFormatSDR'->new($_) };

declare 'RepeatedH264ColorFormatSDR',
    as ArrayRef[H264ColorFormatSDR()];

coerce 'RepeatedH264ColorFormatSDR',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H264ColorFormatSDR'->new($_) } @$_ ] };

declare 'MapStringH264ColorFormatSDR',
    as HashRef[H264ColorFormatSDR()];

declare 'H264ColorFormatHLG',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H264ColorFormatHLG'];

coerce 'H264ColorFormatHLG',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H264ColorFormatHLG'->new($_) };

declare 'RepeatedH264ColorFormatHLG',
    as ArrayRef[H264ColorFormatHLG()];

coerce 'RepeatedH264ColorFormatHLG',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H264ColorFormatHLG'->new($_) } @$_ ] };

declare 'MapStringH264ColorFormatHLG',
    as HashRef[H264ColorFormatHLG()];

declare 'H264CodecSettings',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H264CodecSettings'];

coerce 'H264CodecSettings',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H264CodecSettings'->new($_) };

declare 'RepeatedH264CodecSettings',
    as ArrayRef[H264CodecSettings()];

coerce 'RepeatedH264CodecSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H264CodecSettings'->new($_) } @$_ ] };

declare 'MapStringH264CodecSettings',
    as HashRef[H264CodecSettings()];

declare 'H265ColorFormatSDR',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265ColorFormatSDR'];

coerce 'H265ColorFormatSDR',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265ColorFormatSDR'->new($_) };

declare 'RepeatedH265ColorFormatSDR',
    as ArrayRef[H265ColorFormatSDR()];

coerce 'RepeatedH265ColorFormatSDR',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265ColorFormatSDR'->new($_) } @$_ ] };

declare 'MapStringH265ColorFormatSDR',
    as HashRef[H265ColorFormatSDR()];

declare 'H265ColorFormatHLG',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265ColorFormatHLG'];

coerce 'H265ColorFormatHLG',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265ColorFormatHLG'->new($_) };

declare 'RepeatedH265ColorFormatHLG',
    as ArrayRef[H265ColorFormatHLG()];

coerce 'RepeatedH265ColorFormatHLG',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265ColorFormatHLG'->new($_) } @$_ ] };

declare 'MapStringH265ColorFormatHLG',
    as HashRef[H265ColorFormatHLG()];

declare 'H265ColorFormatHDR10',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265ColorFormatHDR10'];

coerce 'H265ColorFormatHDR10',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265ColorFormatHDR10'->new($_) };

declare 'RepeatedH265ColorFormatHDR10',
    as ArrayRef[H265ColorFormatHDR10()];

coerce 'RepeatedH265ColorFormatHDR10',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265ColorFormatHDR10'->new($_) } @$_ ] };

declare 'MapStringH265ColorFormatHDR10',
    as HashRef[H265ColorFormatHDR10()];

declare 'H265CodecSettings',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265CodecSettings'];

coerce 'H265CodecSettings',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265CodecSettings'->new($_) };

declare 'RepeatedH265CodecSettings',
    as ArrayRef[H265CodecSettings()];

coerce 'RepeatedH265CodecSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::H265CodecSettings'->new($_) } @$_ ] };

declare 'MapStringH265CodecSettings',
    as HashRef[H265CodecSettings()];

declare 'Vp9ColorFormatSDR',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::Vp9ColorFormatSDR'];

coerce 'Vp9ColorFormatSDR',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::Vp9ColorFormatSDR'->new($_) };

declare 'RepeatedVp9ColorFormatSDR',
    as ArrayRef[Vp9ColorFormatSDR()];

coerce 'RepeatedVp9ColorFormatSDR',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::Vp9ColorFormatSDR'->new($_) } @$_ ] };

declare 'MapStringVp9ColorFormatSDR',
    as HashRef[Vp9ColorFormatSDR()];

declare 'Vp9ColorFormatHLG',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::Vp9ColorFormatHLG'];

coerce 'Vp9ColorFormatHLG',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::Vp9ColorFormatHLG'->new($_) };

declare 'RepeatedVp9ColorFormatHLG',
    as ArrayRef[Vp9ColorFormatHLG()];

coerce 'RepeatedVp9ColorFormatHLG',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::Vp9ColorFormatHLG'->new($_) } @$_ ] };

declare 'MapStringVp9ColorFormatHLG',
    as HashRef[Vp9ColorFormatHLG()];

declare 'Vp9CodecSettings',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::Vp9CodecSettings'];

coerce 'Vp9CodecSettings',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::Vp9CodecSettings'->new($_) };

declare 'RepeatedVp9CodecSettings',
    as ArrayRef[Vp9CodecSettings()];

coerce 'RepeatedVp9CodecSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::VideoStream::Vp9CodecSettings'->new($_) } @$_ ] };

declare 'MapStringVp9CodecSettings',
    as HashRef[Vp9CodecSettings()];

declare 'AudioStream',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::AudioStream'];

coerce 'AudioStream',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::AudioStream'->new($_) };

declare 'RepeatedAudioStream',
    as ArrayRef[AudioStream()];

coerce 'RepeatedAudioStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::AudioStream'->new($_) } @$_ ] };

declare 'MapStringAudioStream',
    as HashRef[AudioStream()];

declare 'AudioMapping',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::AudioStream::AudioMapping'];

coerce 'AudioMapping',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::AudioStream::AudioMapping'->new($_) };

declare 'RepeatedAudioMapping',
    as ArrayRef[AudioMapping()];

coerce 'RepeatedAudioMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::AudioStream::AudioMapping'->new($_) } @$_ ] };

declare 'MapStringAudioMapping',
    as HashRef[AudioMapping()];

declare 'TextStream',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::TextStream'];

coerce 'TextStream',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::TextStream'->new($_) };

declare 'RepeatedTextStream',
    as ArrayRef[TextStream()];

coerce 'RepeatedTextStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::TextStream'->new($_) } @$_ ] };

declare 'MapStringTextStream',
    as HashRef[TextStream()];

declare 'TextMapping',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::TextStream::TextMapping'];

coerce 'TextMapping',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::TextStream::TextMapping'->new($_) };

declare 'RepeatedTextMapping',
    as ArrayRef[TextMapping()];

coerce 'RepeatedTextMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::TextStream::TextMapping'->new($_) } @$_ ] };

declare 'MapStringTextMapping',
    as HashRef[TextMapping()];

declare 'SegmentSettings',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::SegmentSettings'];

coerce 'SegmentSettings',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::SegmentSettings'->new($_) };

declare 'RepeatedSegmentSettings',
    as ArrayRef[SegmentSettings()];

coerce 'RepeatedSegmentSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::SegmentSettings'->new($_) } @$_ ] };

declare 'MapStringSegmentSettings',
    as HashRef[SegmentSettings()];

declare 'Encryption',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Encryption'];

coerce 'Encryption',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption'->new($_) };

declare 'RepeatedEncryption',
    as ArrayRef[Encryption()];

coerce 'RepeatedEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption'->new($_) } @$_ ] };

declare 'MapStringEncryption',
    as HashRef[Encryption()];

declare 'Aes128Encryption',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Aes128Encryption'];

coerce 'Aes128Encryption',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Aes128Encryption'->new($_) };

declare 'RepeatedAes128Encryption',
    as ArrayRef[Aes128Encryption()];

coerce 'RepeatedAes128Encryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Aes128Encryption'->new($_) } @$_ ] };

declare 'MapStringAes128Encryption',
    as HashRef[Aes128Encryption()];

declare 'SampleAesEncryption',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Encryption::SampleAesEncryption'];

coerce 'SampleAesEncryption',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::SampleAesEncryption'->new($_) };

declare 'RepeatedSampleAesEncryption',
    as ArrayRef[SampleAesEncryption()];

coerce 'RepeatedSampleAesEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::SampleAesEncryption'->new($_) } @$_ ] };

declare 'MapStringSampleAesEncryption',
    as HashRef[SampleAesEncryption()];

declare 'MpegCommonEncryption',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Encryption::MpegCommonEncryption'];

coerce 'MpegCommonEncryption',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::MpegCommonEncryption'->new($_) };

declare 'RepeatedMpegCommonEncryption',
    as ArrayRef[MpegCommonEncryption()];

coerce 'RepeatedMpegCommonEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::MpegCommonEncryption'->new($_) } @$_ ] };

declare 'MapStringMpegCommonEncryption',
    as HashRef[MpegCommonEncryption()];

declare 'SecretManagerSource',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Encryption::SecretManagerSource'];

coerce 'SecretManagerSource',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::SecretManagerSource'->new($_) };

declare 'RepeatedSecretManagerSource',
    as ArrayRef[SecretManagerSource()];

coerce 'RepeatedSecretManagerSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::SecretManagerSource'->new($_) } @$_ ] };

declare 'MapStringSecretManagerSource',
    as HashRef[SecretManagerSource()];

declare 'Widevine',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Widevine'];

coerce 'Widevine',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Widevine'->new($_) };

declare 'RepeatedWidevine',
    as ArrayRef[Widevine()];

coerce 'RepeatedWidevine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Widevine'->new($_) } @$_ ] };

declare 'MapStringWidevine',
    as HashRef[Widevine()];

declare 'Fairplay',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Fairplay'];

coerce 'Fairplay',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Fairplay'->new($_) };

declare 'RepeatedFairplay',
    as ArrayRef[Fairplay()];

coerce 'RepeatedFairplay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Fairplay'->new($_) } @$_ ] };

declare 'MapStringFairplay',
    as HashRef[Fairplay()];

declare 'Playready',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Playready'];

coerce 'Playready',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Playready'->new($_) };

declare 'RepeatedPlayready',
    as ArrayRef[Playready()];

coerce 'RepeatedPlayready',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Playready'->new($_) } @$_ ] };

declare 'MapStringPlayready',
    as HashRef[Playready()];

declare 'Clearkey',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Clearkey'];

coerce 'Clearkey',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Clearkey'->new($_) };

declare 'RepeatedClearkey',
    as ArrayRef[Clearkey()];

coerce 'RepeatedClearkey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::Clearkey'->new($_) } @$_ ] };

declare 'MapStringClearkey',
    as HashRef[Clearkey()];

declare 'DrmSystems',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Resources::Encryption::DrmSystems'];

coerce 'DrmSystems',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::DrmSystems'->new($_) };

declare 'RepeatedDrmSystems',
    as ArrayRef[DrmSystems()];

coerce 'RepeatedDrmSystems',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Resources::Encryption::DrmSystems'->new($_) } @$_ ] };

declare 'MapStringDrmSystems',
    as HashRef[DrmSystems()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Transcoder::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
