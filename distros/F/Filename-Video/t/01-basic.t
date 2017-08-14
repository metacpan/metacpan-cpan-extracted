#!perl

use strict;
use warnings;
use Test::More 0.98;

use Filename::Video qw(check_video_filename);

ok(!check_video_filename(filename=>"foo.txt"));
ok(!check_video_filename(filename=>"foo.mp3"));
ok( check_video_filename(filename=>"foo.webm"));
ok( check_video_filename(filename=>"foo.MP4"));

done_testing;
