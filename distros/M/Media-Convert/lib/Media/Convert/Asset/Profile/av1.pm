use Media::Convert::Asset::ProfileFactory;
package Media::Convert::Asset::Profile::av1;

use Moose;

extends 'Media::Convert::Asset::Profile::Base';

use Media::Convert::FfmpegInfo;

=head1 NAME

Media::Convert::Asset::Profile::av1 - Create an av1/vorbis video

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::Asset::ProfileFactory
  use Media::Convert::Pipe;

  my $input = Media::Convert::Asset->new(url => $input_filename);
  my $profile = Media::Convert::Asset::ProfileFactory->create("av1", $input);
  my $output = Media::Convert::Asset->new(url => "$output_basename." . $profile->exten, reference => $profile);
  Media::Convert::Pipe->new(inputs => [$input], output => $output)->run();

=head1 DESCRIPTION

The C<av1> profile re-encodes the input video into AV1 with Vorbis audio.

=cut

sub _probe_exten {
	return 'av1.webm';
}

sub _probe_videocodec {
	my $codecs = Media::Convert::FfmpegInfo->instance->codecs;
	die "av1 not supported by ffmpeg" unless exists($codecs->{av1});
	if($codecs->{av1}{description} =~ /libsvtav1/) {
		my $version = Media::Convert::FfmpegInfo->instance->version;
		die "svtav1 support immature by supplied version of ffmpeg" unless $version >= "5.1.0";
		return "libsvtav1";
	} elsif ($codecs->{av1}{description} =~ /libaom/) {
		print STDERR "Warning: libsvtav1 not supported by ffmpeg. Trying libaom-av1 instead, which will probably be too slow...\n";
		return "libaom-av1";
	} else {
		print STDERR "Warning: ffmpeg supports av1, but it is neither libsvtav1 nor libaom-av1. Trying, but not sure what's going to happen...\n";
		return "av1";
	}
}

sub _probe_pix_fmt {
	return "yuv420p10le";
}

sub _probe_audiocodec {
	return "vorbis";
}

sub _probe_quality {
	return 25;
}

sub _probe_video_preset {
	return 4;
}

sub _probe_videobitrate {
	return;
}

sub _probe_videominrate {
	return;
}

sub _probe_videomaxrate {
	return;
}

sub _probe_extra_params {
	return { "svtav1-params" => "tune=0:film-grain=8" };
}

1;
