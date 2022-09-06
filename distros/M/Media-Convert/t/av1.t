#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

use_ok('Media::Convert::Asset');
use_ok('Media::Convert::Asset::ProfileFactory');
use_ok('Media::Convert::Pipe');
use_ok('Media::Convert::FfmpegInfo');

SKIP: {
	skip "libsvtav1 codec not supported by ffmpeg, this will be too slow", 5 unless Media::Convert::FfmpegInfo->instance->codecs->{av1}{description} =~ /libsvtav1/;

	my $input = Media::Convert::Asset->new(url => 't/testvids/bbb.mp4');
	my $profile = Media::Convert::Asset::ProfileFactory->create("av1", $input);
	my $output = Media::Convert::Asset->new(url => './1sec.webm', duration => 0.1, reference => $profile);

	ok(defined($input), "Creating an input asset is possible");
	ok(defined($output), "Creating an output asset is possible");

	Media::Convert::Pipe->new(inputs => [$input], output => $output)->run();

	ok(-f $output->url, "Creating a 0.1 second AV1 file is possible");

	my $check = Media::Convert::Asset->new(url => $output->url);
	ok($check->video_codec eq "av1", "The output video has the correct codec");
	ok($check->duration < 0.15, "The output video has approximately the correct length");

	unlink($check->url);
}

done_testing;
