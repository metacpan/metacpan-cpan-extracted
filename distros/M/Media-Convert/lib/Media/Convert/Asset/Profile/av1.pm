use Media::Convert::Asset::ProfileFactory;
package Media::Convert::Asset::Profile::av1;

use Moose;

extends 'Media::Convert::Asset::Profile::Base';

use Media::Convert::FfmpegInfo;

=head1 NAME

Media::Convert::Asset::Profile::av1 - Create an H.264/AAC video

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::Asset::ProfileFactory
  use Media::Convert::Pipe;

  my $input = Media::Convert::Asset->new(url => $input_filename);
  my $profile = Media::Convert::Asset::ProfileFactory->create("av1", $input);
  my $output = Media::Convert::Asset->new(url => "$output_basename." . $profile->exten, reference => $profile);
  Media::Convert::Pipe->new(inputs => [$input], output => $output)->run();

=head1 DESCRIPTION

The C<av1> profile re-encodes the input video into AV1 with Opus audio.

=cut

sub _probe_exten {
	return 'av1.webm';
}

sub _probe_videocodec {
	if(Media::Convert::FfmpegInfo->instance->codecs->{av1}{description} =~ /libsvtav1/) {
		return "libsvtav1";
	} else {
		print STDERR "Warning: libsvtav1 not supported by ffmpeg. Trying libaom-av1 instead, which will probably be too slow...\n";
		return "libaom-av1";
	}
}

sub _probe_audiocodec {
	return "vorbis";
}

sub _probe_quality {
	return 25;
}

#sub _probe_video_preset {
#	if(shift->video_height > 1080) {
#		return 5;
#	}
#	return 1;
#}

1;
