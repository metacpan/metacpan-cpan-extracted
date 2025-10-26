package Media::Convert::Asset;

use strict;
use warnings;
use v5.24;

our $VERSION;

use Media::Convert;
use Carp;

use autodie qw/:all/;

=head1 NAME

Media::Convert::Asset - Media::Convert representation of a media asset

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::ProfileFactory;
  use Media::Convert::Pipe;

  # convert any input file to VP9 at recommended settings for vertical resolution and frame rate
  my $input = Media::Convert::Asset->new(url => $input_filename);
  my $profile = Media::Convert::ProfileFactory->new("vp9", $input);
  my $output = Media::Convert::Asset->new(url => $output_filename, reference => $profile);
  Media::Convert::Pipe->new(inputs => [$input], output => $output)->run();

  # do that again; but this time, force vorbis audio:
  $output = Media::Convert::Asset->new(url => $other_filename, reference => $profile);
  $output->audio_codec("libvorbis");
  Media::Convert::Pipe->new(inputs => [$input], output => $output)->run();

  # Merge the video stream from one file with the audio stream from another,
  # and convert to VP9
  use Media::Convert::Map;
  my $input_v = Media::Convert::Asset->new(url => $input_video_filename);
  my $input_a = Media::Convert::Asset->new(url => $input_audio_filename);
  $profile = Media::Convert::ProfileFactory->new("vp9", $input);
  $output = Media::Convert::Asset->new(url => $merged_filename, reference => $profile);
  my $map_v = Media::Convert::Map->new(input => $input_v, type => "stream", choice => "video");
  my $map_a = Media::Convert::Map->new(input => $input_a, type => "stream", choice => "audio");
  Media::Convert::Pipe->new(inputs => [$input_a, $input_v], map => [$map_a, $map_v], output => $output)->run();

=head1 DESCRIPTION

The C<Media::Convert::Asset> package is used to represent media assets
inside C<Media::Convert>. It is a C<Moose>-based base class for much of
the other classes in C<Media::Convert>.

There is one required attribute, C<url>, which represents the filename
of the asset.

If the C<url> attribute points to an existing file and an attempt is
made to read any of the codec, framerate, bit rate, or similar
attributes (without explicitly writing to them first), then
C<Media::Convert::Asset> will call C<ffprobe> on the file in question,
and use that to populate the requested attributes. If it does not, or
C<ffprobe> is incapable of detecting the requested attribute (which may
be the case for things like audio or video bitrate), then the attribute
in question will resolve to C<undef>.

If the C<url> attribute does not point to an existing file and an
attempt is made to read any of the codec, framerate, bit rate, or
similar attributes (without explicitly writing to them first), then they
will resolve to C<undef>. However, if the C<reference> attribute is
populated with another C<Media::Convert::Asset> object, then reading any of the
codec, framerate, bit rate, or similar attributes (without explicitly
writing to them first) will resolve to the value of the requested
attribute that is set or detected on the C<reference> object.

The return value of C<Media::Convert::ProfileFactory-E<gt>create()> is
also a Media::Convert object, but with different implementations of
some of the probing methods; this allows it to choose the correct values
for things like bitrate and encoder speed based on properties set in the
input object provided to the
C<Media::Convert::ProfileFactory-E<gt>create()> method.

For more information on how to use the files referred to in the
C<Media::Convert::Asset> object in an ffmpeg command line, please see
C<Media::Convert::Pipe>.

=head1 ATTRIBUTES

The following attributes are supported by C<Media::Convert::Asset>. All
attributes will be probed from ffprobe output unless noted otherwise.

=cut

use JSON::MaybeXS qw(decode_json);
use Media::Convert::CodecMap qw/detect_to_write/;

use Moose;

=head2 url

The filename of the asset this object should deal with. Required at
construction time. Will not be probed.

=cut

has 'url' => (
	is => 'rw',
	required => 1,
);

=head2 mtime

The mtime of the file backing this asset. Only defined if the file
exists at the time the attribute is first read, and is not updated later
on.

=cut

has 'mtime' => (
	is => 'ro',
	lazy => 1,
	builder => '_probe_mtime',
);

sub _probe_mtime {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->mtime;
	}
	my @statdata = stat($self->url);
	if(scalar(@statdata) == 0) {
		return;
	}
	return $statdata[9];
}

=head2 canonical_duration

Which value to take as the canonical duration while probing the duration
of a media file.

Unfortunately, some versions of ffprobe have bugs in that they either
read or write corrupt values for some parts of a media file. Sometimes
the video stream length is correct but the container length is not,
sometimes it is the other way around.

Since, given that, it is not possible to choose a source that will
always work as the probed value for the L<duration> attribute, this
needs to be configurable in some way.

This option can take the following values:

=over 4

=item container

Uses the duration value that is parsed from the container file, rather
than any particular stream. If the parsing of that value is not buggy,
this is the right thing to do, and therefore this is also the default.

=item video

Uses the duration value that is parsed from the first video stream.

=item audio

Uses the duration value that is parsed from the first audio stream.

=back

=cut

has 'canonical_duration' => (
	is => 'ro',
	isa => 'Str',
	default => 'container',
);

=head2 duration

The duration of this asset. See C<canonical_duration> for details on how
it is probed.

=cut

has 'duration' => (
	is => 'rw',
	builder => '_probe_duration',
	lazy => 1,
);

sub _probe_duration {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->duration;
	}
	if($self->duration_style eq "seconds") {
		if($self->canonical_duration eq 'container') {
			return $self->_get_probedata->{format}{duration};
		} elsif($self->canonical_duration eq 'video') {
			return $self->_get_videodata->{duration};
		} elsif($self->canonical_duration eq 'audio') {
			return $self->_get_audiodata->{duration};
		} else {
			# don't support this
			...
		}
	} else {
		return $self->duration_frames;
	}
}

=head2 duration_frames

The number of frames in this asset.

=cut

has 'duration_frames' => (
	is => 'rw',
	builder => '_probe_duration_frames',
	lazy => 1,
);

sub _probe_duration_frames {
	return shift->_get_videodata->{duration_ts};
}

=head2 duration_style

The time unit is used for the C<duration> attribute. One of 'seconds'
(default) or 'frames'. Will not be probed.

Deprecated; will be removed in a future release. Use duration_frames
instead of setting this to a non-default value.

=cut

sub _warn_duration {
	carp "setting duration_style is deprecated. Rather use duration_frames."
}

has 'duration_style' => (
	is => 'rw',
	default => 'seconds',
	trigger => \&_warn_duration,
);

=head2 force_key_frames

Can be set to an expression that can be passed to ffmpeg's C<-force_key_frames>
parameter. Will not be probed.

=cut

has 'force_key_frames' => (
	is => 'rw',
	isa => 'Maybe[Str]',
	builder => '_probe_force_key_frames',
	lazy => 1,
	predicate => 'has_force_key_frames',
);

sub _probe_force_key_frames {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->force_key_frames;
	}
	return;
}

=head2 video_codec

The codec in use for the video stream. Note that C<ffprobe> will
sometimes use a string (e.g., "vp8") that is not the best choice when
instructing C<ffmpeg> to transcode video to the said codec (for vp8, the
use of "libvpx" is recommended). C<Media::Convert::CodecMap> is used to
map detected codecs to output codecs and resolve this issue.

=cut

has 'video_codec' => (
	is => 'rw',
	builder => '_probe_videocodec',
	lazy => 1,
);

sub _probe_videocodec {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->video_codec;
	}
	return $self->_get_videodata->{codec_name};
}

=head2 audio_codec

The codec in use for the audio stream. Note that C<ffprobe> will
sometimes use a string (e.g., "vorbis") that is not the best choice when
instructing C<ffmpeg> to transcode audio to the said codec (for vorbis,
the use of "libvorbis" is recommended). C<Media::Convert::CodecMap> is used to
map detected codecs to output codecs and resolve this issue.

=cut

has 'audio_codec' => (
	is => 'rw',
	builder => '_probe_audiocodec',
	lazy => 1,
);

sub _probe_audiocodec {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->audio_codec;
	}
	return $self->_get_audiodata->{codec_name};
}

=head2 video_size

A string representing the resolution of the video in C<WxH> format,
where W is the width and H is the height.

This attribute is special in that in contrast to all the other
attributes, it is not provided directly by C<ffprobe>; instead, when
this parameter is read, the C<video_width> and C<video_height>
attributes are read and combined.

That does mean that you should not read this attribute, and based on
that possibly set the height and/or width attributes of a video (or vice
versa). Instead, you should read I<either> the C<video_width> and
C<video_height> attribute, I<or> this one.

Failure to follow this rule will result in undefined behaviour.

=cut

has 'video_size' => (
	is => 'rw',
	builder => '_probe_videosize',
	lazy => 1,
	predicate => 'has_video_size',
);

sub _probe_videosize {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->video_size;
	}
	my $width = $self->video_width;
	my $height = $self->video_height;
	return unless defined($width) && defined($height);
	return $self->video_width . "x" . $self->video_height;
}

=head2 video_width

The width of the video, in pixels.

=cut

has 'video_width' => (
	is => 'rw',
	builder => '_probe_width',
	lazy => 1,
);

sub _probe_width {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->video_width;
	}
	if($self->has_video_size) {
		return (split /x/, $self->video_size)[0];
	} else {
		return $self->_get_videodata->{width};
	}
}

=head2 video_height

The height of the video, in pixels.

=cut

has 'video_height' => (
	is => 'rw',
	builder => '_probe_height',
	lazy => 1,
);

sub _probe_height {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->video_height;
	}
	if($self->has_video_size) {
		return (split /x/, $self->video_size)[1];
	} else {
		return $self->_get_videodata->{height};
	}
}

=head2 video_bitrate

The bit rate of this video, in bits per second.

Note that not all container formats support probing the bitrate of the
encoded video or audio; when read on input objects with those that do
not, this will resolve to C<undef>.

=cut

has 'video_bitrate' => (
	is => 'rw',
	builder => '_probe_videobitrate',
	lazy => 1,
);

sub _probe_videobitrate {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->video_bitrate;
	}
	my $bitrate = $self->_get_videodata->{bit_rate};
	if(defined($bitrate) && (!($bitrate =~ /k/))) {
		return $bitrate / 1000;
	}
	return $bitrate;
}

=head2 video_minrate

The minimum bit rate for this video, in bits per second.

Defaults to 0.5 * video_bitrate

=cut

has 'video_minrate' => (
	is => 'rw',
	builder => '_probe_videominrate',
	lazy => 1,
);

sub _probe_videominrate {
	my $self = shift;
	my $rate;
	if($self->has_reference) {
		$rate = $self->reference->video_minrate;
		if(defined($rate)) {
			return $rate;
		}
	}
	$rate = $self->video_bitrate;
	if(defined($rate)) {
		return $rate * 0.5;
	}
	return;
}

=head2 video_maxrate

The maximum bit rate for this video, in bits per second.

Defaults to 1.45 * video_bitrate

=cut

has 'video_maxrate' => (
	is => 'rw',
	builder => '_probe_videomaxrate',
	lazy => 1,
);

=head2 video_preset

The value for the -preset parameter. Used by some codecs, like av1 (and
pretty critical there).

=cut

has 'video_preset' => (
	is => 'rw',
	builder => '_probe_video_preset',
	lazy => 1,
);

sub _probe_video_preset {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->video_preset;
	}
	return;
}

sub _probe_videomaxrate {
	my $self = shift;
	my $rate;
	if($self->has_reference) {
		$rate = $self->reference->video_maxrate;
		if(defined($rate)) {
			return $rate;
		}
	}
	$rate = $self->video_bitrate;
	if(defined($rate)) {
		return $rate * 1.45;
	}
	return;
}

=head2 aspect_ratio

The Display Aspect Ratio of a video. Note that with non-square pixels,
this is not guaranteed to be what one would expect when reading the
C<video_size> attribute.

=cut

has 'aspect_ratio' => (
	is => 'rw',
	builder => '_probe_aspect_ratio',
	lazy => 1,
);

sub _probe_aspect_ratio {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->aspect_ratio;
	}
	return $self->_get_videodata->{display_aspect_ratio};
}

=head2 audio_bitrate

The bit rate of the audio stream on this video, in bits per second

=cut

has 'audio_bitrate' => (
	is => 'rw',
	builder => '_probe_audiobitrate',
	lazy => 1,
);

sub _probe_audiobitrate {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->audio_bitrate;
	}
	return $self->_get_audiodata->{bit_rate};
}

=head2 audio_samplerate

The sample rate of the audio, in samples per second

=cut

has 'audio_samplerate' => (
	is => 'rw',
	builder => '_probe_audiorate',
	lazy => 1,
);

sub _probe_audiorate {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->audio_samplerate;
	}
	return $self->_get_audiodata->{sample_rate};
}

=head2 video_framerate

The frame rate of the video, as a fraction.

Note that in the weird US frame rate, this could be 30000/1001.

=cut

has 'video_framerate' => (
	is => 'rw',
	builder => '_probe_framerate',
	lazy => 1,
);

sub _probe_framerate {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->video_framerate;
	}
	my $framerate = $self->_get_videodata->{r_frame_rate};
	return $framerate;
}

=head2 video_frame_length

The length of a single video frame in seconds, as a floating point number.

Calculated as 1 / (video_framerate numerator / video_framerate denumerator)

Probed from the value of video_framerate. Ignored if set.

=cut

has 'video_frame_length' => (
	is => 'rw',
	builder => '_probe_frame_length',
	lazy => 1,
);

sub _probe_frame_length {
	my $self = shift;

	my ($numerator, $denumerator) = split /\//, $self->video_framerate;
	return 1 / ($numerator / $denumerator);
}

=head2 fragment_start

If set, this instructs Media::Convert on read to only read a particular
part of the video from this file. Should be specified in seconds; will
not be probed.

=cut

has 'fragment_start' => (
	is => 'rw',
	predicate => 'has_fragment_start',
);

=head2 quality

The quality used for the video encoding, i.e., the value passed to the C<-crf>
parameter. Mostly for use by a profile. Will not be probed.

=cut

has 'quality' => (
	is => 'rw',
	builder => '_probe_quality',
	lazy => 1,
);

sub _probe_quality {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->quality;
	}
	return;
}

=head2 metadata

Can be used to set video metadata (as per C<ffmpeg>'s C<-metadata>
parameter). Functions C<add_metadata> and C<drop_metadata> can be used
to add or remove individual metedata values. Will not be probed.

=cut

has 'metadata' => (
	traits => ['Hash'],
	isa => 'HashRef[Str]',
	is => 'ro',
	handles => {
		add_metadata => 'set',
		drop_metadata => 'delete',
	},
	predicate => 'has_metadata',
);

=head2 reference

If set to any C<Media::Convert::Asset> object, then when any value is being
probed, rather than trying to run C<ffprobe> on the file pointed to by
our C<url> attribute, we will use the value reported by the referenced
object.

Can be used in "build a file almost like this one, but with these things
different" kind of scenarios.

Will not be probed (obviously).

=cut

has 'reference' => (
	isa => 'Media::Convert::Asset',
	is => 'ro',
	predicate => 'has_reference',
);

=head2 pix_fmt

The pixel format (e.g., C<yuv420p> or the likes) of the video.

=cut

has 'pix_fmt' => (
	is => 'rw',
	builder => '_probe_pix_fmt',
	lazy => 1,
);

sub _probe_pix_fmt {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->pix_fmt;
	}
	return $self->_get_videodata->{pix_fmt};
}

=head2 astream_id

Returns the numeric ID for the first audio stream in this file. Useful for the
implementation of stream mappings etc; see C<Media::Convert::Map>

=cut

has 'astream_id' => (
	is => 'rw',
	builder => '_probe_astream_id',
	lazy => 1,
);

sub _probe_astream_id {
	my $self = shift;
	return $self->_get_audiodata->{index};
}

=head2 blackspots

Returns an array of hashes. Each hash contains a member C<start>,
C<end>, and C<duration>, containing the start, end, and duration,
respectively, of locations in the video file that are (almost) entirely
black.

Could be used by a script for automatic review.

Note that the ffmpeg run required to detect blackness is CPU intensive
and may require a very long time to finish.

=cut

has blackspots => (
	is => 'ro',
	isa => 'ArrayRef[HashRef[Num]]',
	builder => '_probe_blackspots',
	lazy => 1,
);

sub _probe_blackspots {
	my $self = shift;
	my $blacks = [];
	pipe my $R, my $W;
	if(fork == 0) {
		open STDERR, ">", "$W";
		open STDOUT, ">", "$W";
		my @cmd = ("ffmpeg", "-threads", "1", "-nostats", "-i", $self->url, "-vf", "blackdetect=d=0:pix_th=.01", "-f", "null", "/dev/null");
		exec @cmd;
		die "exec failed";
	}
	close $W;
	while(<$R>) {
		if(/blackdetect.*black_start:(?<start>[\d\.]+)\sblack_end:(?<end>[\d\.]+)\sblack_duration:(?<duration>[\d\.]+)/) {
			push @$blacks, { %+ };
		}
	}
	close($R);
	return $blacks;
}


=head2 channel_layouts

Returns an array of audio channel layouts, as detected by ffprobe.

=cut

has 'channel_layouts' => (
	is => 'rw',
	traits => ['Array'],
	isa => 'ArrayRef[Str]',
	builder => '_probe_channel_layouts',
	lazy => 1,
);

sub _probe_channel_layouts {
	my $self = shift;
	my $rv = [];
	foreach my $stream(@{$self->_get_probedata->{streams}}) {
		if($stream->{codec_type} eq "audio") {
			push @$rv, $stream->{channel_layout};
		}
	}
	return $rv;
}

=head2 astream_ids

Returns an array with the IDs for the audio streams in this file.

=head2 astream_count

Returns the number of audio streams in this file. 

=cut

has 'astream_ids' => (
	is => 'rw',
	traits => ['Array'],
	isa => 'ArrayRef[Int]',
	builder => '_probe_astream_ids',
	lazy => 1,
	handles => {
		astream_count => "count",
	},
);

sub _probe_astream_ids {
	my $self = shift;
	my $rv = [];
	foreach my $stream(@{$self->_get_probedata->{streams}}) {
		if($stream->{codec_type} eq "audio") {
			push @$rv, $stream->{index};
		}
	}
	return $rv;
}

=head2 audio_channel_count

Returns the number of channels in the first audio stream

=cut

has 'audio_channel_count' => (
	is => 'rw',
	isa => 'Int',
	lazy => 1,
	builder => '_probe_audio_channel_count',
);

sub _probe_audio_channel_count {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->audio_channel_count;
	}
	return $self->_get_audiodata->{channels};
}

=head2 vstream_id

Returns the numeric ID for the first video stream in this file. Useful
for the implementation of stream mappings etc; see C<Media::Convert::Map>

=cut

has 'vstream_id' => (
	is => 'rw',
	builder => '_probe_vstream_id',
	lazy => 1,
);

sub _probe_vstream_id {
	my $self = shift;
	return $self->_get_videodata->{index};
}

=head2 extra_params

Add extra (output) parameters. This should be used sparingly, rather add some
abstraction.

=head3 handles

=over

=item *

add_param (adds an extra parameter)

=item *

drop_param (delete a parameter)

=back

=cut

has 'extra_params' => (
	traits => ['Hash'],
	isa => 'HashRef[Str]',
	is => 'ro',
	handles => {
		add_param => 'set',
		drop_param => 'delete',
	},
	builder => "_probe_extra_params",
	lazy => 1,
);

sub _probe_extra_params {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->extra_params;
	}
	return {};
}

=head2 input_params

Add extra input parameters. This should be used sparingly, rather add
some abstraction.

=head3 handles

=over

=item *

add_input_param (adds an extra parameter)

=item *

drop_input_param (delete a parameter)

=back

=cut

has 'input_params' => (
	traits => ['Hash'],
	isa => 'HashRef[Str]',
	is => 'ro',
	handles => {
		add_input_param => 'set',
		drop_input_param => 'delete',
	},
	builder => "_probe_input_params",
	lazy => 1,
);

sub _probe_input_params {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->input_params;
	}
	return {};
}

=head2 time_offset

Apply an input time offset to this video (only valid when used as an
input video in L<Media::Convert::Pipe>). Can be used to apply A/V sync
correction values.

=cut

has 'time_offset' => (
	isa => 'Num',
	is => 'ro',
	predicate => 'has_time_offset',
);

# Only to be used by the Pipe class when doing multiple passes
has 'pass' => (
	is => 'rw',
	predicate => 'has_pass',
	clearer => 'clear_pass',
);

## The below exist to help autodetect sizes, and are not meant for the end user
has 'videodata' => (
	is => 'bare',
	reader => '_get_videodata',
	builder => '_probe_videodata',
	lazy => 1,
);
has 'audiodata' => (
	is => 'bare',
	reader => '_get_audiodata',
	builder => '_probe_audiodata',
	lazy => 1,
);
has 'probedata' => (
	is => 'bare',
	reader => '_get_probedata',
	builder => '_probe',
	clearer => 'clear_probedata',
	lazy => 1,
);

sub readopts {
	my $self = shift;
	my @opts = ();

	if($self->has_time_offset) {
		push @opts, ("-itsoffset", $self->time_offset);
	}

	if(scalar(keys(%{$self->input_params})) > 0) {
		foreach my $param(keys %{$self->input_params}) {
			push @opts, ("-$param", $self->input_params->{$param});
		}
	}

	push @opts, ("-i", $self->url);
	return @opts;
}

sub writeopts {
	my $self = shift;
	my $pipe = shift;
	my @opts = ();

	if(!$pipe->vcopy && !$pipe->vskip) {
		push @opts, ('-threads', '1');
		if(defined($self->video_codec)) {
			push @opts, ('-c:v', detect_to_write($self->video_codec));
		}
		if(defined($self->video_bitrate)) {
			push @opts, ('-b:v', $self->video_bitrate . "k", '-minrate', $self->video_minrate . "k", '-maxrate', $self->video_maxrate . "k");
		}
		if(defined($self->video_framerate)) {
			push @opts, ('-r:v', $self->video_framerate);
		}
		if(defined($self->quality)) {
			push @opts, ('-crf', $self->quality);
		}
		if(defined($self->speed)) {
			push @opts, ('-speed', $self->speed);
		}
		if(defined($self->video_preset)) {
			push @opts, ('-preset', $self->video_preset);
		}
		if(defined($self->force_key_frames)) {
			push @opts, ('-force_key_frames', $self->force_key_frames);
		}
		if($self->has_pass) {
			push @opts, ('-pass', $self->pass, '-passlogfile', $self->url . '-multipass');
		}
	}
	if(!$pipe->acopy && !$pipe->askip) {
		if(defined($self->audio_codec)) {
			push @opts, ('-c:a', detect_to_write($self->audio_codec));
		}
		if(defined($self->audio_bitrate)) {
			push @opts, ('-b:a', $self->audio_bitrate);
		}
		if(defined($self->audio_samplerate)) {
			push @opts, ('-ar', $self->audio_samplerate);
		}
	}
	if($self->has_fragment_start) {
		push @opts, ('-ss', $self->fragment_start);
	}
	if(defined($self->duration)) {
		if($self->duration_style eq 'seconds') {
			push @opts, ('-t', $self->duration);
		} else {
			push @opts, ('-frames:v', $self->duration);
		}
	} elsif(defined($self->duration_frames)) {
		push @opts, ('-frames:v', $self->duration_frames);
	}
	if(defined($self->pix_fmt)) {
		push @opts, ('-pix_fmt', $self->pix_fmt);
	}
	if($self->has_metadata) {
		foreach my $meta(keys %{$self->metadata}) {
			push @opts, ('-metadata', $meta . '=' . $self->metadata->{$meta});
		}
	}

	if(!defined($self->duration) && $#{$pipe->inputs}>0) {
		push @opts, '-shortest';
	}

	if(scalar(keys(%{$self->extra_params}))>0) {
		foreach my $param(keys %{$self->extra_params}) {
			push @opts, ("-$param", $self->extra_params->{$param});
		}
	}

	if(exists($ENV{SREVIEW_NONSTRICT})) {
		push @opts, ("-strict", "-2");
	}

	push @opts, $self->url;

	return @opts;
}

sub _probe {
	my $self = shift;

	if($self->has_reference) {
		return $self->reference->_get_probedata;
	}
	if(-e $self->url) {
		open my $jsonpipe, "-|:encoding(UTF-8)", "ffprobe", "-loglevel", "quiet", "-print_format", "json", "-show_format", "-show_streams", $self->url;
		my $json = "";
		while(<$jsonpipe>) {
			$json .= $_;
		}
		close $jsonpipe;
		return decode_json($json);
	}
	return {};
}

sub _probe_audiodata {
	my $self = shift;
	if(!exists($self->_get_probedata->{streams})) {
		return {};
	}
	foreach my $stream(@{$self->_get_probedata->{streams}}) {
		if($stream->{codec_type} eq "audio") {
			return $stream;
		}
	}
	return {};
}

sub _probe_videodata {
	my $self = shift;
	if(!exists($self->_get_probedata->{streams})) {
		return {};
	}
	foreach my $stream(@{$self->_get_probedata->{streams}}) {
		if($stream->{codec_type} eq "video") {
			return $stream;
		}
	}
	return {};
}

sub speed {
	my $self = shift;
	if($self->has_reference) {
		return $self->reference->speed;
	}
	return 4;
}

no Moose;

1;
