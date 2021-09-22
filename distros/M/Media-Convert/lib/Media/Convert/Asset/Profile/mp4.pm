use Media::Convert::Asset::ProfileFactory;
package Media::Convert::Asset::Profile::mp4;

use Moose;

extends 'Media::Convert::Asset::Profile::Base';

=head1 NAME

Media::Convert::Asset::Profile::mp4 - Create an H.264/AAC video

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::Asset::ProfileFactory
  use Media::Convert::Pipe;

  my $input = Media::Convert::Asset->new(url => $input_filename);
  my $profile = Media::Convert::Asset::ProfileFactory->create("mp4", $input);
  my $output = Media::Convert::Asset->new(url => "$output_basename." . $profile->exten, reference => $profile);
  Media::Convert::Pipe->new(inputs => [$input], output => $output)->run();

=head1 DESCRIPTION

The C<mp4> profile re-encodes the input video into MPEG-4 H.264 with AAC
audio.

=cut

sub _probe_exten {
	return 'mp4';
}

sub _probe_videocodec {
	return "h264";
}

sub _probe_audiocodec {
	return "aac";
}

1;
