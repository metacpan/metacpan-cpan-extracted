package Media::Convert::Map;

use Moose;
use Carp;

=head1 NAME

Media::Convert::Map - Map streams and/or channels from an input asset into an output

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::Map;
  use Media::Convert::Pipe;

  my $input_video = Media::Convert::Asset->new(url => $input_with_video);
  my $input_audio = Media::Convert::Asset->new(url => $input_with_two_stereo_audio_streams);
  my $output = Media::Convert::Asset->new(url => $output_filename);

  # Merge the video from $input_video with the first audio stream from
  # $input_audio:
  my $map_video = Media::Convert::Map->new(input => $input_video, type => "stream", choice => "video");
  my $map_audio = Media::Convert::Map->new(input => $input_audio, type => "stream", choice => "audio");
  Media::Convert::Pipe->new(input => [$input_video, $input_audio], map => [$map_video, $map_audio], output => $output, vcopy => 1, acopy => 1)->run;

  # or, extract only the first audio stream:
  Media::Convert::Pipe->new(input => [$input_audio], map => [$map_audio], output => $output, acopy => 1, vskip => 1)->run;

  # or, extract the second audio stream:
  my $map_2nd_audio = Media::Convert::Map->new(input => $input_audio, type => "astream", choice => "2");
  Media::Convert::Pipe->new(input => [$input_audio], map => [$map_2nd_audio], output => $output, vskip => 1, acopy => 1);

  # or, extract only the left audio channel from the first audio stream
  # into a mono audio asset:
  my $map_left_audio = Media::Convert::Map->new(input => $input_audio, type => "channel", choice => "left");
  Media::Convert::Pipe->new(input => [$input_audio], map => [$map_left_audio], output => $output, vskip => 1, acopy => 1);

=head1 DESCRIPTION

Media::Convert::Map is a helper object used to configure a
L<Media::Asset::Pipe> to route various audio or video streams and
channels into particular locations.

It has three options: C<input>, which must be the
L<Media::Convert::Asset> from which we want to map a stream or channel;
C<type>, which selects the type of routing to configure, and C<choice>,
which selects which input stream or channel to use from the selected
type.

The values for C<type> and C<choice> work together; the values of
C<type> define what the valid values of C<choice> are.

=head1 ATTRIBUTES

=head2 input

The asset from which we are reading data. I<Must> be passed to the same
C<Media::Convert::Pipe> as one of the elements in the input array.

=cut

has 'input' => (
	required => 1,
	is => 'rw',
	isa => 'Media::Convert::Asset',
);

=head2 type

The type of map that is being created. Must be one these options:

=head3 channel

Selects an audio channel from the first audio stream in the file, or
mixes the first two audio channels from the first audio stream into one
mono stream in the output file.

This value is the default.

Valid values for C<choice> when this type is selected, are:

=over

=item left

Select the left channel in the first audio stream (assuming it is a
stereo stream)

=item right

Select the right channel in the first audio stream

=item both

Use C<-ac 1> to perform a downmix of all audio channels in the first
audio stream into a single mono channel.

=back

=head3 stream

Selects either the first audio or the first video stream in the file

Valid values for C<choice> when this type is selected, are:

=over

=item audio

Select the first audio stream from the input file

=item video

Select the first video stream from the input file

=back

=head3 astream

Selects a specific audio stream from the file, or allows to merge the
first two audio streams into a single audio stream, using the C<amix>
ffmpeg filter.

Valid values for C<choice> when this type is selected, are:

=over

=item -1

Use the C<amix> ffmpeg filter to downmix the first two audio streams
from the file into a single audio stream.

=item any other number

Select the Nth audio stream from the input file, where N is the number
given.

It is an error to choose an audio stream with an index that is higher
than the total number of audio streams in the input file. To discover the
number of audio streams in a file, use the
L<Media::Convert::Asset/astream_count> method.

=back

=head3 allcopy

Copy all streams.

The default behavior of ffmpeg is to copy only the first audio stream,
the first video stream, and the first subtitle stream, from the input
file into the output file.

When this is not wanted, a Media::Convert::Map object of type "allcopy"
will copy I<all> streams, not just the first of each type, into the
output file.

If this option is chosen, no choice value should be selected (any value
given is ignored).

=head3 none

No routing is done. This has the same effect as not passing any
C<Media::Convert::Map> object to C<Media::Convert::Pipe>.

=cut

has 'type' => (
	isa => 'Str',
	is => 'rw',
	default => 'channel',
);

has 'choice' => (
	isa => 'Str',
	is => 'rw',
	default => 'left',
);

sub arguments {
	my $self = shift;
	my $index = shift;
	my $stream_id;

	if($self->type eq "channel") {
		if($self->choice eq "both") {
			return ('-ac', '1');
		}
                my $channel_layout = $self->input->channel_layouts->[0];
                if($self->choice ne "left" && $self->choice ne "right") {
                        # not supported
                        croak("Invalid audio channel choice");
                }
		$stream_id = $self->input->astream_id;
                my $choice = $self->choice eq "left" ? 1 : 2;
                return ("-filter_complex", "[$index:$stream_id]channelsplit=channel_layout=" . $channel_layout . ":channels=${choice}" . "[out]", "-map", "[out]");
	} elsif($self->type eq "stream") {
		if($self->choice eq 'audio') {
			return ('-map', "$index:a");
		} elsif($self->choice eq 'video') {
			return ('-map', "$index:v");
		} else {
			...
		}
	} elsif($self->type eq "astream") {
		my $choice = $self->choice;
		if($choice > $self->input->astream_count) {
			croak("Invalid audio stream, not supported by input video");
		}
		if($choice == -1) {
			my $ids = $self->input->astream_ids;
			my $id1 = $ids->[0];
			my $id2 = $ids->[1];
			return ('-filter_complex', "[$index:$id1][$index:$id2]amix=inputs=2:duration=first");
		}
		return ('-map', "$index:a:$choice");
	} elsif($self->type eq "allcopy") {
		return ('-map', '0');
	} elsif($self->type eq "none") {
		return ();
	} else {
		...
	}
}

no Moose;

1;
