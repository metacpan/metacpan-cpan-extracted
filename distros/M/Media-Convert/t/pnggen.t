#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 8;

use_ok("Media::Convert::Asset::PNGGen");
use_ok("Media::Convert::Asset");
use_ok("Media::Convert::Pipe");

my $input = Media::Convert::Asset::PNGGen->new(url => "t/testvids/m-c.png");
isa_ok($input, "Media::Convert::Asset");
isa_ok($input, "Media::Convert::Asset::PNGGen");
my $output = Media::Convert::Asset->new(url => "./test.mkv", duration => 5, video_framerate => 25);
isa_ok($output, "Media::Convert::Asset");

Media::Convert::Pipe->new(inputs => [$input], output => $output)->run;

my $check = Media::Convert::Asset->new(url => $output->url);

ok(int($check->duration) == 5, "The video is created with the correct length");
ok($check->astream_count == 1, "Exactly one audio stream is created");

unlink($output->url);
