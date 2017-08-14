#!perl

use strict;
use warnings;
use Test::More 0.98;

use Filename::Media qw(check_media_filename);

ok(!check_media_filename(filename=>"foo.txt"));
ok(!check_media_filename(filename=>"foo.DOC"));
ok( check_media_filename(filename=>"foo.webm"));
ok( check_media_filename(filename=>"foo.MP3"));
ok( check_media_filename(filename=>"foo.Jpeg"));

done_testing;
