#!perl

use strict;
use warnings;
use Test::More 0.98;

use Filename::Audio qw(check_audio_filename);

ok(!check_audio_filename(filename=>"foo.txt"));
ok(!check_audio_filename(filename=>"foo.mp4"));
ok( check_audio_filename(filename=>"foo.wav"));
ok( check_audio_filename(filename=>"foo.MP3"));

done_testing;
