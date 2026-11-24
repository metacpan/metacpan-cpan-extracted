package Google::Cloud::Video::Livestream::Logging::V1::Logs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ChannelActivity',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::ChannelActivity'];

coerce 'ChannelActivity',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::ChannelActivity'->new($_) };

declare 'RepeatedChannelActivity',
    as ArrayRef[ChannelActivity()];

coerce 'RepeatedChannelActivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::ChannelActivity'->new($_) } @$_ ] };

declare 'MapStringChannelActivity',
    as HashRef[ChannelActivity()];

declare 'StreamingStateChange',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingStateChange'];

coerce 'StreamingStateChange',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingStateChange'->new($_) };

declare 'RepeatedStreamingStateChange',
    as ArrayRef[StreamingStateChange()];

coerce 'RepeatedStreamingStateChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingStateChange'->new($_) } @$_ ] };

declare 'MapStringStreamingStateChange',
    as HashRef[StreamingStateChange()];

declare 'StreamingError',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingError'];

coerce 'StreamingError',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingError'->new($_) };

declare 'RepeatedStreamingError',
    as ArrayRef[StreamingError()];

coerce 'RepeatedStreamingError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingError'->new($_) } @$_ ] };

declare 'MapStringStreamingError',
    as HashRef[StreamingError()];

declare 'InputAccept',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::InputAccept'];

coerce 'InputAccept',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::InputAccept'->new($_) };

declare 'RepeatedInputAccept',
    as ArrayRef[InputAccept()];

coerce 'RepeatedInputAccept',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::InputAccept'->new($_) } @$_ ] };

declare 'MapStringInputAccept',
    as HashRef[InputAccept()];

declare 'InputError',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::InputError'];

coerce 'InputError',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::InputError'->new($_) };

declare 'RepeatedInputError',
    as ArrayRef[InputError()];

coerce 'RepeatedInputError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::InputError'->new($_) } @$_ ] };

declare 'MapStringInputError',
    as HashRef[InputError()];

declare 'InputStreamProperty',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::InputStreamProperty'];

coerce 'InputStreamProperty',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::InputStreamProperty'->new($_) };

declare 'RepeatedInputStreamProperty',
    as ArrayRef[InputStreamProperty()];

coerce 'RepeatedInputStreamProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::InputStreamProperty'->new($_) } @$_ ] };

declare 'MapStringInputStreamProperty',
    as HashRef[InputStreamProperty()];

declare 'VideoStream',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoStream'];

coerce 'VideoStream',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoStream'->new($_) };

declare 'RepeatedVideoStream',
    as ArrayRef[VideoStream()];

coerce 'RepeatedVideoStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoStream'->new($_) } @$_ ] };

declare 'MapStringVideoStream',
    as HashRef[VideoStream()];

declare 'VideoFormat',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoFormat'];

coerce 'VideoFormat',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoFormat'->new($_) };

declare 'RepeatedVideoFormat',
    as ArrayRef[VideoFormat()];

coerce 'RepeatedVideoFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoFormat'->new($_) } @$_ ] };

declare 'MapStringVideoFormat',
    as HashRef[VideoFormat()];

declare 'AudioStream',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioStream'];

coerce 'AudioStream',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioStream'->new($_) };

declare 'RepeatedAudioStream',
    as ArrayRef[AudioStream()];

coerce 'RepeatedAudioStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioStream'->new($_) } @$_ ] };

declare 'MapStringAudioStream',
    as HashRef[AudioStream()];

declare 'AudioFormat',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioFormat'];

coerce 'AudioFormat',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioFormat'->new($_) };

declare 'RepeatedAudioFormat',
    as ArrayRef[AudioFormat()];

coerce 'RepeatedAudioFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioFormat'->new($_) } @$_ ] };

declare 'MapStringAudioFormat',
    as HashRef[AudioFormat()];

declare 'InputDisconnect',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::InputDisconnect'];

coerce 'InputDisconnect',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::InputDisconnect'->new($_) };

declare 'RepeatedInputDisconnect',
    as ArrayRef[InputDisconnect()];

coerce 'RepeatedInputDisconnect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::InputDisconnect'->new($_) } @$_ ] };

declare 'MapStringInputDisconnect',
    as HashRef[InputDisconnect()];

declare 'EventStateChange',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::EventStateChange'];

coerce 'EventStateChange',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::EventStateChange'->new($_) };

declare 'RepeatedEventStateChange',
    as ArrayRef[EventStateChange()];

coerce 'RepeatedEventStateChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::EventStateChange'->new($_) } @$_ ] };

declare 'MapStringEventStateChange',
    as HashRef[EventStateChange()];

declare 'Scte35Command',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command'];

coerce 'Scte35Command',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command'->new($_) };

declare 'RepeatedScte35Command',
    as ArrayRef[Scte35Command()];

coerce 'RepeatedScte35Command',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command'->new($_) } @$_ ] };

declare 'MapStringScte35Command',
    as HashRef[Scte35Command()];

declare 'SpliceTime',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::SpliceTime'];

coerce 'SpliceTime',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::SpliceTime'->new($_) };

declare 'RepeatedSpliceTime',
    as ArrayRef[SpliceTime()];

coerce 'RepeatedSpliceTime',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::SpliceTime'->new($_) } @$_ ] };

declare 'MapStringSpliceTime',
    as HashRef[SpliceTime()];

declare 'BreakDuration',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::BreakDuration'];

coerce 'BreakDuration',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::BreakDuration'->new($_) };

declare 'RepeatedBreakDuration',
    as ArrayRef[BreakDuration()];

coerce 'RepeatedBreakDuration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::BreakDuration'->new($_) } @$_ ] };

declare 'MapStringBreakDuration',
    as HashRef[BreakDuration()];

declare 'Component',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::Component'];

coerce 'Component',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::Component'->new($_) };

declare 'RepeatedComponent',
    as ArrayRef[Component()];

coerce 'RepeatedComponent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::Component'->new($_) } @$_ ] };

declare 'MapStringComponent',
    as HashRef[Component()];

declare 'SpliceInsert',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::SpliceInsert'];

coerce 'SpliceInsert',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::SpliceInsert'->new($_) };

declare 'RepeatedSpliceInsert',
    as ArrayRef[SpliceInsert()];

coerce 'RepeatedSpliceInsert',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::SpliceInsert'->new($_) } @$_ ] };

declare 'MapStringSpliceInsert',
    as HashRef[SpliceInsert()];

declare 'SpliceInfoSection',
    as InstanceOf['Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::SpliceInfoSection'];

coerce 'SpliceInfoSection',
    from HashRef, via { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::SpliceInfoSection'->new($_) };

declare 'RepeatedSpliceInfoSection',
    as ArrayRef[SpliceInfoSection()];

coerce 'RepeatedSpliceInfoSection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::SpliceInfoSection'->new($_) } @$_ ] };

declare 'MapStringSpliceInfoSection',
    as HashRef[SpliceInfoSection()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Livestream::Logging::V1::Logs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
