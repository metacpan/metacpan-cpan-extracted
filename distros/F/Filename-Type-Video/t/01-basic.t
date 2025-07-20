#!perl

use strict;
use warnings;
use Test::More 0.98;

use Filename::Type::Video qw(check_video_filename);

ok(!check_video_filename(filename=>"foo.txt"));
ok(!check_video_filename(filename=>"foo.mp3"));
ok( check_video_filename(filename=>"foo.webm"));
ok( check_video_filename(filename=>"foo.MP4"));

is_deeply(check_video_filename(filename=>"foo.MP4"), {filename=>'foo.MP4', filename_without_suffix=>"foo", "suffix"=>"MP4"});

done_testing;
