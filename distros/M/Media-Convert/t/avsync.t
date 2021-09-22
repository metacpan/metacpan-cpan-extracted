#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 15;
use_ok("Media::Convert::Asset");
use_ok("Media::Convert::AvSync");

my $input = Media::Convert::Asset->new(url => "t/testvids/bbb.mp4");
isa_ok($input, "Media::Convert::Asset");
my $output = Media::Convert::Asset->new(url => "./test.mkv");
isa_ok($output, "Media::Convert::Asset");
my $avsync = Media::Convert::AvSync->new(input => $input, output => $output, audio_delay => 0);
isa_ok($avsync, "Media::Convert::AvSync");
$avsync->run;
ok(-f $output->url, "Doing A/V sync creates a file, even with no actual A/V sync");
my $check = Media::Convert::Asset->new(url => $output->url);
ok($check->video_size eq $input->video_size, "The video was generated with the correct output size");
ok($check->video_codec eq $input->video_codec, "The video was copied correctly");
ok($check->audio_codec eq $input->audio_codec, "The audio was copied correctly");
ok(int($check->duration) == int($input->duration), "The output duration is about the same as that of the input");
unlink($check->url);
$avsync->audio_delay(1);
$avsync->run;
ok(-f $output->url, "Doing A/V sync with audio delay creates a file");
ok($check->video_size eq $input->video_size, "The video was generated with the correct output size");
ok($check->video_codec eq $input->video_codec, "The video was copied correctly");
ok($check->audio_codec eq $input->audio_codec, "The audio was copied correctly");
ok($check->duration < $input->duration, "The output duration is shorter than the input duration");
unlink($check->url);
