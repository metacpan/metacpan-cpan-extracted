use Media::Convert::Asset::ProfileFactory;
package Media::Convert::Asset::Profile::mpeg2;

use Moose;

extends 'Media::Convert::Asset::Profile::Base';

=head1 NAME

Media::Conert::Asset::Profile::mpeg2 - Create an MPEG-2 video

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::Asset::ProfileFactory;
  use Media::Convert::Pipe;

  my $input = Media::Convert::Asset->new(url => $input_filename);
  my $profile = Media::Convert::Asset::ProfileFactory->create("mpeg2", $input);
  my $output = Media::Convert::Asset-new(url => "$output_basename." .  $profile->exten, reference => $profile);
  Media::Convert::Pipe->new(inputs => [$input], output => $output)->run();

=head1 DESCRIPTION

The C<mpeg2> profile re-encodes the input video into MPEG-2 video with
MPEG-2 audio.

=cut

sub _probe_exten {
	return 'mpg';
}

sub _probe_videocodec {
	return "mpeg2video";
}

sub _probe_audiocodec {
	return "mp2";
}

sub _probe_videobitrate {
	return undef;
}

sub _probe_audiobitrate {
	return undef;
}

1;
