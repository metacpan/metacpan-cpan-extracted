#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('Media::Convert::Asset');
use_ok('Media::Convert::AccurateCut');
use_ok('Media::Convert::Asset::ProfileFactory');
use_ok('Media::Convert::KeyframeFinder');

my @testcases = (
	{ name => 'within two key frames', start => 1, duration => 1, expected_duration => 1 },
	{ name => 'straddling a key frame', start => 3, duration => 2, expected_duration => 2 },
	{ name => 'less than half a frame before a key frame', start => 3.165, expected_duration => 20 - 3.16666667 },
	{ name => 'less than half a frame after a key frame', start => 3.168, expected_duration => 20 - 3.16666667 },
);

my $input = Media::Convert::Asset->new(url => 't/testvids/bbb.mp4');
my $iprof = Media::Convert::Asset::ProfileFactory->create("mp4", $input);
my $prof = Media::Convert::Asset::ProfileFactory->create("vp8", $input);

foreach my $testcase(@testcases) {
	my $out = Media::Convert::Asset->new(url => './out.mkv', reference => $prof);
	my $cut = Media::Convert::AccurateCut->new(input => $input, output => $out, profile => $iprof, start => $testcase->{start});
	if(exists($testcase->{duration})) {
		$cut->duration($testcase->{duration});
	}
	lives_ok(sub {$cut->run}, 'Running the accurate cut does not die when rquesting a cut ' . $testcase->{name});

	my $check = Media::Convert::Asset->new(url => $out->url);
	my $kfs = Media::Convert::KeyframeFinder->new(asset => $check)->keyframes;

	ok($kfs->[0] == 0, 'The first frame of the output video is a key frame when requesting a cut ' . $testcase->{name});
	ok($testcase->{expected_duration} - $check->video_frame_length < $check->duration
		&& $check->duration < $testcase->{expected_duration} + $check->video_frame_length, 'The video has the expected length when requesting a cut ' . $testcase->{name});
	unlink($out->url);
}

done_testing;
