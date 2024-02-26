package Media::Convert::AvSync;

use Moose;
use Media::Convert::Asset;
use Media::Convert::Pipe;
use Media::Convert::Map;
use File::Temp qw/tempdir/;

=head1 NAME

Media::Convert::AvSync - Helper module to fix A/V synchronization issues.

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::AvSync;
  
  my $input = Media::Convert::Asset->new(url => $input_filename);
  my $output = Media::Convert::Asset->new(url => $output_filename);
  Media::Convert::AvSync->new(input => $input, output => $output, audio_delay => 0.1)->run();

=head1 DESCRIPTION

Media::Convert::AvSync is a higher-level helper module to correct
audio/video synchronization issues.

It does this by instructing ffmpeg to read the input asset twice (once
for audio, once for video), and to apply a time offset to the audio
stream. This offset may be negative, in case audio precedes video.

Note that after A/V sync correction, the asset file will be reduced in
length by twice the length of the correction value; this is because
otherwise, in the case of audio preceding video, the resulting media
file would end up with a snippet of audio with no video at the start,
and one of video with no audio at the end (and vice versa for a
correction value for video preceding audio).

=head1 ATTRIBUTES

The following attributes are supported by Media::Convert::AvSync:

=head2 input

The input asset. Must be a Media::Convert::Asset object.

=cut

has "input" => (
	is => 'rw',
	required => 1,
	isa => 'Media::Convert::Asset',
);

=head2 output

The output asset. Must be a Media::Convert::Asset object.

=cut

has 'output' => (
	is => 'rw',
	required => 1,
	isa => 'Media::Convert::Asset',
);

=head2 audio_delay

The delay that should be applied to the audio in the input asset. Should
be expressed in seconds; may be a fractional and/or negative value.

Postive values delay the audio; negative values delay the video.

=cut

has "audio_delay" => (
	is => 'rw',
	required => 1,
);

sub run() {
	my $self = shift;
	my $tempdir = tempdir("avsXXXXXX", CLEANUP => 1, TMPDIR => 1);
	if($self->audio_delay == 0) {
		# Why are we here??
		Media::Convert::Pipe->new(inputs => [$self->input], output => $self->output)->run();
		return;
	}
	Media::Convert::Pipe->new(inputs => [$self->input], output => Media::Convert::Asset->new(url => "$tempdir/pre.mkv"))->run();
	my $input_audio = Media::Convert::Asset->new(url => "$tempdir/pre.mkv", time_offset => $self->audio_delay);
	my $input_video = Media::Convert::Asset->new(url => "$tempdir/pre.mkv");
	my $sync_video = Media::Convert::Asset->new(url => "$tempdir/synced.mkv");
	Media::Convert::Pipe->new(inputs => [$input_audio, $input_video], map => [Media::Convert::Map->new(input => $input_audio, type => "stream", choice => "audio"), Media::Convert::Map->new(input => $input_video, type => "stream", choice => "video")], output => $sync_video)->run();
	$self->output->fragment_start(abs($self->audio_delay));
	Media::Convert::Pipe->new(inputs => [$sync_video], output => $self->output)->run();
}

1;
