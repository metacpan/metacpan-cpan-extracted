package Google::Cloud::Video::Livestream::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Input',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Input'];

coerce 'Input',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Input'->new($_) };

declare 'RepeatedInput',
    as ArrayRef[Input()];

coerce 'RepeatedInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Input'->new($_) } @$_ ] };

declare 'MapStringInput',
    as HashRef[Input()];

declare 'Type',
    as (Int | Str);

declare 'Tier',
    as (Int | Str);

declare 'SecurityRule',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Input::SecurityRule'];

coerce 'SecurityRule',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Input::SecurityRule'->new($_) };

declare 'RepeatedSecurityRule',
    as ArrayRef[SecurityRule()];

coerce 'RepeatedSecurityRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Input::SecurityRule'->new($_) } @$_ ] };

declare 'MapStringSecurityRule',
    as HashRef[SecurityRule()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Input::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Input::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Input::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Channel',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Channel'];

coerce 'Channel',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Channel'->new($_) };

declare 'RepeatedChannel',
    as ArrayRef[Channel()];

coerce 'RepeatedChannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Channel'->new($_) } @$_ ] };

declare 'MapStringChannel',
    as HashRef[Channel()];

declare 'StreamingState',
    as (Int | Str);

declare 'Output',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Channel::Output'];

coerce 'Output',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Channel::Output'->new($_) };

declare 'RepeatedOutput',
    as ArrayRef[Output()];

coerce 'RepeatedOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Channel::Output'->new($_) } @$_ ] };

declare 'MapStringOutput',
    as HashRef[Output()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Channel::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Channel::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Channel::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NormalizedCoordinate',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::NormalizedCoordinate'];

coerce 'NormalizedCoordinate',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::NormalizedCoordinate'->new($_) };

declare 'RepeatedNormalizedCoordinate',
    as ArrayRef[NormalizedCoordinate()];

coerce 'RepeatedNormalizedCoordinate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::NormalizedCoordinate'->new($_) } @$_ ] };

declare 'MapStringNormalizedCoordinate',
    as HashRef[NormalizedCoordinate()];

declare 'NormalizedResolution',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::NormalizedResolution'];

coerce 'NormalizedResolution',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::NormalizedResolution'->new($_) };

declare 'RepeatedNormalizedResolution',
    as ArrayRef[NormalizedResolution()];

coerce 'RepeatedNormalizedResolution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::NormalizedResolution'->new($_) } @$_ ] };

declare 'MapStringNormalizedResolution',
    as HashRef[NormalizedResolution()];

declare 'StaticOverlay',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::StaticOverlay'];

coerce 'StaticOverlay',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::StaticOverlay'->new($_) };

declare 'RepeatedStaticOverlay',
    as ArrayRef[StaticOverlay()];

coerce 'RepeatedStaticOverlay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::StaticOverlay'->new($_) } @$_ ] };

declare 'MapStringStaticOverlay',
    as HashRef[StaticOverlay()];

declare 'InputConfig',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::InputConfig'];

coerce 'InputConfig',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::InputConfig'->new($_) };

declare 'RepeatedInputConfig',
    as ArrayRef[InputConfig()];

coerce 'RepeatedInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::InputConfig'->new($_) } @$_ ] };

declare 'MapStringInputConfig',
    as HashRef[InputConfig()];

declare 'InputSwitchMode',
    as (Int | Str);

declare 'LogConfig',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::LogConfig'];

coerce 'LogConfig',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::LogConfig'->new($_) };

declare 'RepeatedLogConfig',
    as ArrayRef[LogConfig()];

coerce 'RepeatedLogConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::LogConfig'->new($_) } @$_ ] };

declare 'MapStringLogConfig',
    as HashRef[LogConfig()];

declare 'LogSeverity',
    as (Int | Str);

declare 'RetentionConfig',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::RetentionConfig'];

coerce 'RetentionConfig',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::RetentionConfig'->new($_) };

declare 'RepeatedRetentionConfig',
    as ArrayRef[RetentionConfig()];

coerce 'RepeatedRetentionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::RetentionConfig'->new($_) } @$_ ] };

declare 'MapStringRetentionConfig',
    as HashRef[RetentionConfig()];

declare 'InputStreamProperty',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::InputStreamProperty'];

coerce 'InputStreamProperty',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::InputStreamProperty'->new($_) };

declare 'RepeatedInputStreamProperty',
    as ArrayRef[InputStreamProperty()];

coerce 'RepeatedInputStreamProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::InputStreamProperty'->new($_) } @$_ ] };

declare 'MapStringInputStreamProperty',
    as HashRef[InputStreamProperty()];

declare 'VideoStreamProperty',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::VideoStreamProperty'];

coerce 'VideoStreamProperty',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::VideoStreamProperty'->new($_) };

declare 'RepeatedVideoStreamProperty',
    as ArrayRef[VideoStreamProperty()];

coerce 'RepeatedVideoStreamProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::VideoStreamProperty'->new($_) } @$_ ] };

declare 'MapStringVideoStreamProperty',
    as HashRef[VideoStreamProperty()];

declare 'VideoFormat',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::VideoFormat'];

coerce 'VideoFormat',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::VideoFormat'->new($_) };

declare 'RepeatedVideoFormat',
    as ArrayRef[VideoFormat()];

coerce 'RepeatedVideoFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::VideoFormat'->new($_) } @$_ ] };

declare 'MapStringVideoFormat',
    as HashRef[VideoFormat()];

declare 'AudioStreamProperty',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::AudioStreamProperty'];

coerce 'AudioStreamProperty',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::AudioStreamProperty'->new($_) };

declare 'RepeatedAudioStreamProperty',
    as ArrayRef[AudioStreamProperty()];

coerce 'RepeatedAudioStreamProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::AudioStreamProperty'->new($_) } @$_ ] };

declare 'MapStringAudioStreamProperty',
    as HashRef[AudioStreamProperty()];

declare 'AudioFormat',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::AudioFormat'];

coerce 'AudioFormat',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::AudioFormat'->new($_) };

declare 'RepeatedAudioFormat',
    as ArrayRef[AudioFormat()];

coerce 'RepeatedAudioFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::AudioFormat'->new($_) } @$_ ] };

declare 'MapStringAudioFormat',
    as HashRef[AudioFormat()];

declare 'InputAttachment',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::InputAttachment'];

coerce 'InputAttachment',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::InputAttachment'->new($_) };

declare 'RepeatedInputAttachment',
    as ArrayRef[InputAttachment()];

coerce 'RepeatedInputAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::InputAttachment'->new($_) } @$_ ] };

declare 'MapStringInputAttachment',
    as HashRef[InputAttachment()];

declare 'AutomaticFailover',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::InputAttachment::AutomaticFailover'];

coerce 'AutomaticFailover',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::InputAttachment::AutomaticFailover'->new($_) };

declare 'RepeatedAutomaticFailover',
    as ArrayRef[AutomaticFailover()];

coerce 'RepeatedAutomaticFailover',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::InputAttachment::AutomaticFailover'->new($_) } @$_ ] };

declare 'MapStringAutomaticFailover',
    as HashRef[AutomaticFailover()];

declare 'AutoTranscriptionConfig',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::AutoTranscriptionConfig'];

coerce 'AutoTranscriptionConfig',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::AutoTranscriptionConfig'->new($_) };

declare 'RepeatedAutoTranscriptionConfig',
    as ArrayRef[AutoTranscriptionConfig()];

coerce 'RepeatedAutoTranscriptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::AutoTranscriptionConfig'->new($_) } @$_ ] };

declare 'MapStringAutoTranscriptionConfig',
    as HashRef[AutoTranscriptionConfig()];

declare 'DisplayTiming',
    as (Int | Str);

declare 'QualityPreset',
    as (Int | Str);

declare 'Event',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'State',
    as (Int | Str);

declare 'InputSwitchTask',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Event::InputSwitchTask'];

coerce 'InputSwitchTask',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Event::InputSwitchTask'->new($_) };

declare 'RepeatedInputSwitchTask',
    as ArrayRef[InputSwitchTask()];

coerce 'RepeatedInputSwitchTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Event::InputSwitchTask'->new($_) } @$_ ] };

declare 'MapStringInputSwitchTask',
    as HashRef[InputSwitchTask()];

declare 'AdBreakTask',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Event::AdBreakTask'];

coerce 'AdBreakTask',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Event::AdBreakTask'->new($_) };

declare 'RepeatedAdBreakTask',
    as ArrayRef[AdBreakTask()];

coerce 'RepeatedAdBreakTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Event::AdBreakTask'->new($_) } @$_ ] };

declare 'MapStringAdBreakTask',
    as HashRef[AdBreakTask()];

declare 'SlateTask',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Event::SlateTask'];

coerce 'SlateTask',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Event::SlateTask'->new($_) };

declare 'RepeatedSlateTask',
    as ArrayRef[SlateTask()];

coerce 'RepeatedSlateTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Event::SlateTask'->new($_) } @$_ ] };

declare 'MapStringSlateTask',
    as HashRef[SlateTask()];

declare 'ReturnToProgramTask',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Event::ReturnToProgramTask'];

coerce 'ReturnToProgramTask',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Event::ReturnToProgramTask'->new($_) };

declare 'RepeatedReturnToProgramTask',
    as ArrayRef[ReturnToProgramTask()];

coerce 'RepeatedReturnToProgramTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Event::ReturnToProgramTask'->new($_) } @$_ ] };

declare 'MapStringReturnToProgramTask',
    as HashRef[ReturnToProgramTask()];

declare 'MuteTask',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Event::MuteTask'];

coerce 'MuteTask',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Event::MuteTask'->new($_) };

declare 'RepeatedMuteTask',
    as ArrayRef[MuteTask()];

coerce 'RepeatedMuteTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Event::MuteTask'->new($_) } @$_ ] };

declare 'MapStringMuteTask',
    as HashRef[MuteTask()];

declare 'UnmuteTask',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Event::UnmuteTask'];

coerce 'UnmuteTask',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Event::UnmuteTask'->new($_) };

declare 'RepeatedUnmuteTask',
    as ArrayRef[UnmuteTask()];

coerce 'RepeatedUnmuteTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Event::UnmuteTask'->new($_) } @$_ ] };

declare 'MapStringUnmuteTask',
    as HashRef[UnmuteTask()];

declare 'UpdateEncryptionsTask',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Event::UpdateEncryptionsTask'];

coerce 'UpdateEncryptionsTask',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Event::UpdateEncryptionsTask'->new($_) };

declare 'RepeatedUpdateEncryptionsTask',
    as ArrayRef[UpdateEncryptionsTask()];

coerce 'RepeatedUpdateEncryptionsTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Event::UpdateEncryptionsTask'->new($_) } @$_ ] };

declare 'MapStringUpdateEncryptionsTask',
    as HashRef[UpdateEncryptionsTask()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Event::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Event::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Event::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Clip',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Clip'];

coerce 'Clip',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Clip'->new($_) };

declare 'RepeatedClip',
    as ArrayRef[Clip()];

coerce 'RepeatedClip',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Clip'->new($_) } @$_ ] };

declare 'MapStringClip',
    as HashRef[Clip()];

declare 'State',
    as (Int | Str);

declare 'OutputType',
    as (Int | Str);

declare 'TimeSlice',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Clip::TimeSlice'];

coerce 'TimeSlice',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Clip::TimeSlice'->new($_) };

declare 'RepeatedTimeSlice',
    as ArrayRef[TimeSlice()];

coerce 'RepeatedTimeSlice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Clip::TimeSlice'->new($_) } @$_ ] };

declare 'MapStringTimeSlice',
    as HashRef[TimeSlice()];

declare 'Slice',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Clip::Slice'];

coerce 'Slice',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Clip::Slice'->new($_) };

declare 'RepeatedSlice',
    as ArrayRef[Slice()];

coerce 'RepeatedSlice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Clip::Slice'->new($_) } @$_ ] };

declare 'MapStringSlice',
    as HashRef[Slice()];

declare 'ClipManifest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Clip::ClipManifest'];

coerce 'ClipManifest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Clip::ClipManifest'->new($_) };

declare 'RepeatedClipManifest',
    as ArrayRef[ClipManifest()];

coerce 'RepeatedClipManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Clip::ClipManifest'->new($_) } @$_ ] };

declare 'MapStringClipManifest',
    as HashRef[ClipManifest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Clip::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Clip::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Clip::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TimeInterval',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::TimeInterval'];

coerce 'TimeInterval',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::TimeInterval'->new($_) };

declare 'RepeatedTimeInterval',
    as ArrayRef[TimeInterval()];

coerce 'RepeatedTimeInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::TimeInterval'->new($_) } @$_ ] };

declare 'MapStringTimeInterval',
    as HashRef[TimeInterval()];

declare 'DvrSession',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::DvrSession'];

coerce 'DvrSession',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::DvrSession'->new($_) };

declare 'RepeatedDvrSession',
    as ArrayRef[DvrSession()];

coerce 'RepeatedDvrSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::DvrSession'->new($_) } @$_ ] };

declare 'MapStringDvrSession',
    as HashRef[DvrSession()];

declare 'State',
    as (Int | Str);

declare 'DvrManifest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::DvrSession::DvrManifest'];

coerce 'DvrManifest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::DvrSession::DvrManifest'->new($_) };

declare 'RepeatedDvrManifest',
    as ArrayRef[DvrManifest()];

coerce 'RepeatedDvrManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::DvrSession::DvrManifest'->new($_) } @$_ ] };

declare 'MapStringDvrManifest',
    as HashRef[DvrManifest()];

declare 'DvrWindow',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::DvrSession::DvrWindow'];

coerce 'DvrWindow',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::DvrSession::DvrWindow'->new($_) };

declare 'RepeatedDvrWindow',
    as ArrayRef[DvrWindow()];

coerce 'RepeatedDvrWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::DvrSession::DvrWindow'->new($_) } @$_ ] };

declare 'MapStringDvrWindow',
    as HashRef[DvrWindow()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::DvrSession::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::DvrSession::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::DvrSession::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Asset',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Asset'];

coerce 'Asset',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Asset'->new($_) };

declare 'RepeatedAsset',
    as ArrayRef[Asset()];

coerce 'RepeatedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Asset'->new($_) } @$_ ] };

declare 'MapStringAsset',
    as HashRef[Asset()];

declare 'State',
    as (Int | Str);

declare 'VideoAsset',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Asset::VideoAsset'];

coerce 'VideoAsset',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Asset::VideoAsset'->new($_) };

declare 'RepeatedVideoAsset',
    as ArrayRef[VideoAsset()];

coerce 'RepeatedVideoAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Asset::VideoAsset'->new($_) } @$_ ] };

declare 'MapStringVideoAsset',
    as HashRef[VideoAsset()];

declare 'ImageAsset',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Asset::ImageAsset'];

coerce 'ImageAsset',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Asset::ImageAsset'->new($_) };

declare 'RepeatedImageAsset',
    as ArrayRef[ImageAsset()];

coerce 'RepeatedImageAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Asset::ImageAsset'->new($_) } @$_ ] };

declare 'MapStringImageAsset',
    as HashRef[ImageAsset()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Asset::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Asset::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Asset::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Encryption',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Encryption'];

coerce 'Encryption',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption'->new($_) };

declare 'RepeatedEncryption',
    as ArrayRef[Encryption()];

coerce 'RepeatedEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption'->new($_) } @$_ ] };

declare 'MapStringEncryption',
    as HashRef[Encryption()];

declare 'SecretManagerSource',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Encryption::SecretManagerSource'];

coerce 'SecretManagerSource',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::SecretManagerSource'->new($_) };

declare 'RepeatedSecretManagerSource',
    as ArrayRef[SecretManagerSource()];

coerce 'RepeatedSecretManagerSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::SecretManagerSource'->new($_) } @$_ ] };

declare 'MapStringSecretManagerSource',
    as HashRef[SecretManagerSource()];

declare 'Widevine',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Encryption::Widevine'];

coerce 'Widevine',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::Widevine'->new($_) };

declare 'RepeatedWidevine',
    as ArrayRef[Widevine()];

coerce 'RepeatedWidevine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::Widevine'->new($_) } @$_ ] };

declare 'MapStringWidevine',
    as HashRef[Widevine()];

declare 'Fairplay',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Encryption::Fairplay'];

coerce 'Fairplay',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::Fairplay'->new($_) };

declare 'RepeatedFairplay',
    as ArrayRef[Fairplay()];

coerce 'RepeatedFairplay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::Fairplay'->new($_) } @$_ ] };

declare 'MapStringFairplay',
    as HashRef[Fairplay()];

declare 'Playready',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Encryption::Playready'];

coerce 'Playready',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::Playready'->new($_) };

declare 'RepeatedPlayready',
    as ArrayRef[Playready()];

coerce 'RepeatedPlayready',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::Playready'->new($_) } @$_ ] };

declare 'MapStringPlayready',
    as HashRef[Playready()];

declare 'Clearkey',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Encryption::Clearkey'];

coerce 'Clearkey',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::Clearkey'->new($_) };

declare 'RepeatedClearkey',
    as ArrayRef[Clearkey()];

coerce 'RepeatedClearkey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::Clearkey'->new($_) } @$_ ] };

declare 'MapStringClearkey',
    as HashRef[Clearkey()];

declare 'DrmSystems',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Encryption::DrmSystems'];

coerce 'DrmSystems',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::DrmSystems'->new($_) };

declare 'RepeatedDrmSystems',
    as ArrayRef[DrmSystems()];

coerce 'RepeatedDrmSystems',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::DrmSystems'->new($_) } @$_ ] };

declare 'MapStringDrmSystems',
    as HashRef[DrmSystems()];

declare 'Aes128Encryption',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Encryption::Aes128Encryption'];

coerce 'Aes128Encryption',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::Aes128Encryption'->new($_) };

declare 'RepeatedAes128Encryption',
    as ArrayRef[Aes128Encryption()];

coerce 'RepeatedAes128Encryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::Aes128Encryption'->new($_) } @$_ ] };

declare 'MapStringAes128Encryption',
    as HashRef[Aes128Encryption()];

declare 'SampleAesEncryption',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Encryption::SampleAesEncryption'];

coerce 'SampleAesEncryption',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::SampleAesEncryption'->new($_) };

declare 'RepeatedSampleAesEncryption',
    as ArrayRef[SampleAesEncryption()];

coerce 'RepeatedSampleAesEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::SampleAesEncryption'->new($_) } @$_ ] };

declare 'MapStringSampleAesEncryption',
    as HashRef[SampleAesEncryption()];

declare 'MpegCommonEncryption',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Encryption::MpegCommonEncryption'];

coerce 'MpegCommonEncryption',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::MpegCommonEncryption'->new($_) };

declare 'RepeatedMpegCommonEncryption',
    as ArrayRef[MpegCommonEncryption()];

coerce 'RepeatedMpegCommonEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Encryption::MpegCommonEncryption'->new($_) } @$_ ] };

declare 'MapStringMpegCommonEncryption',
    as HashRef[MpegCommonEncryption()];

declare 'EncryptionUpdate',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::EncryptionUpdate'];

coerce 'EncryptionUpdate',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::EncryptionUpdate'->new($_) };

declare 'RepeatedEncryptionUpdate',
    as ArrayRef[EncryptionUpdate()];

coerce 'RepeatedEncryptionUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::EncryptionUpdate'->new($_) } @$_ ] };

declare 'MapStringEncryptionUpdate',
    as HashRef[EncryptionUpdate()];

declare 'Pool',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Pool'];

coerce 'Pool',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Pool'->new($_) };

declare 'RepeatedPool',
    as ArrayRef[Pool()];

coerce 'RepeatedPool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Pool'->new($_) } @$_ ] };

declare 'MapStringPool',
    as HashRef[Pool()];

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Pool::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Pool::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Pool::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Resources::Pool::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Resources::Pool::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Resources::Pool::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Livestream::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
