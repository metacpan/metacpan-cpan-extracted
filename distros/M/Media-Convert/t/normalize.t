#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 9;
use_ok("Media::Convert::Asset");
use_ok("Media::Convert::Normalizer");

my $input = Media::Convert::Asset->new(url => "t/testvids/bbb.mp4");
isa_ok($input, "Media::Convert::Asset");
my $output = Media::Convert::Asset->new(url => "./test.mkv");
isa_ok($output, "Media::Convert::Asset");
my $norm = Media::Convert::Normalizer->new(input => $input, output => $output);
isa_ok($norm, 'Media::Convert::Normalizer');
$norm->run();
my $check = Media::Convert::Asset->new(url => $output->url);
ok($check->video_size eq $input->video_size, "The video was generated with the correct output size");
ok($check->video_codec eq $input->video_codec, "The video was copied correctly");
ok($check->audio_codec eq $input->audio_codec, "The audio was encoded correctly");
ok(int($check->duration) == int($input->duration), "The duration has not changed significantly");
unlink($output->url);
