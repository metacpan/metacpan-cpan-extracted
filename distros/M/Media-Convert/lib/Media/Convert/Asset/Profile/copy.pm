package Media::Convert::Asset::Profile::copy;

use Media::Convert::Asset::ProfileFactory;
use Media::Convert::CodecMap qw/detect_to_write/;

use Moose;

extends 'Media::Convert::Asset::Profile::Base';

=head1 NAME

Media::Convert::Asset::Profile::copy - Profile that merely copies all data, unmodified.

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::Asset::ProfileFactory;
  use Media::Convert::Pipe;

  my $input = Media::Convert::Asset->new(url => $input_filename);
  my $profile = Media::Convert::Asset::ProfileFactory->create("copy", $input);
  my $output = Media::Convert::Asset->new(url => "$output_basename." . $profile->exten, reference => $profile);
  Media::Convert::Pipe->new(inputs => [$input], output => $output)->run();

=head1 DESCRIPTION

The C<copy> profile copies the input video into the output container,
without any re-encoding.

It only works in one of the following conditions:

=over

=item *

the video codec is VP9 and the audio codec is opus (the extension will
be .webm)

=item *

the video codec is VP8 and the audio codec is vorbis (the extension will
be .webm)

=item *

the video codec is H.264 and the audio codec is AAC (the extension will
be .mp4)

=back

All other cases are currently unsupported (but could be added if
required).

The C<copy> profile has the exact same effect as using the
L<Media::Convert::Pipe/vcopy> and L<Media::Convert::Pipe/acopy> options
on C<Media::Convert::Pipe>, but is expressed as a profile.

=cut

sub _probe_exten {
	my $self = shift;
	my $ref = $self->reference;
	my $vid = $ref->video_codec;
	my $aud = $ref->audio_codec;

	if (($vid eq 'vp9' && $aud eq 'opus')
		or ($vid eq 'vp8' && $aud eq 'vorbis')) {
		return 'webm';
	}
	if ($vid eq 'h264' && $aud eq 'aac') {
		return 'mp4';
	}
	...
}

sub _probe_videocodec {
	return "copy";
}

sub _probe_audiocodec {
	return "copy";
}

1;
