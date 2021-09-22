#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 10;
use_ok('Media::Convert::Asset');
use_ok('Media::Convert::Pipe');

my $input = Media::Convert::Asset->new(url => 't/testvids/bbb.mp4');
isa_ok($input, 'Media::Convert::Asset');
my $output = Media::Convert::Asset->new(url => 't/testvids/1sec.webm', video_codec => 'libvpx-vp9', quality => 32, audio_codec => 'libopus', duration => 1, audio_bitrate => '128k');
isa_ok($output, 'Media::Convert::Asset');
my $pipe = Media::Convert::Pipe->new(inputs => [$input], output => $output, vcopy => 0, acopy => 0);
isa_ok($pipe, 'Media::Convert::Pipe');
$pipe->run;
ok(-f $output->url, 'The output file exists');
my $check = Media::Convert::Asset->new(url => $output->url);
isa_ok($check, 'Media::Convert::Asset');
ok($check->video_size eq $input->video_size, 'The video was generated with the correct output size');
ok($check->video_codec eq 'vp9', 'The video is encoded using VP9');
ok($check->audio_codec eq 'opus', 'The audio is encoded using Opus');
unlink($output->url);
