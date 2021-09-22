#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 45;

use_ok("Media::Convert::Asset");
use_ok("Media::Convert::Asset::ProfileFactory");
use_ok("Media::Convert::Pipe");

my $input = Media::Convert::Asset->new(url => "t/testvids/bbb.mp4");
isa_ok($input, "Media::Convert::Asset");

sub test_profile {
	my $profilename = shift;
	my $video_codec = shift;
	my $audio_codec = shift;
	my $extra_classes = shift;

	my $profile_classes = [ "Media::Convert::Asset", "Media::Convert::Asset::Profile::Base", "Media::Convert::Asset::Profile::$profilename"];
	while(defined($extra_classes) && scalar(@$extra_classes) > 0) {
		push @$profile_classes, (shift @$extra_classes);
	}
	my $profile = Media::Convert::Asset::ProfileFactory->create($profilename, $input);
	foreach my $class(@$profile_classes) {
		isa_ok($profile, $class);
	}
	my $output = Media::Convert::Asset->new(url => "./test." . $profile->exten, reference => $profile);
	isa_ok($output, "Media::Convert::Asset");
	Media::Convert::Pipe->new(inputs => [$input], output => $output)->run();
	ok(-f $output->url, "Running conversion with the $profilename profile creates a file");
	my $check = Media::Convert::Asset->new(url => $output->url);
	ok($check->video_codec eq $video_codec, "The $profilename profile generates $video_codec video");
	ok($check->audio_codec eq $audio_codec, "The $profilename profile generates $audio_codec audio");
	ok(int($check->duration) == int($input->duration), "The duration of the output video is approximately the same as the input video");
	unlink($check->url);
}
test_profile("webm", "vp9", "opus", ["Media::Convert::Asset::Profile::vp9"]);
test_profile("vp8", "vp8", "vorbis");
test_profile("mp4", "h264", "aac");
test_profile("mpeg2", "mpeg2video", "mp2");
test_profile("copy", $input->video_codec, $input->audio_codec);
