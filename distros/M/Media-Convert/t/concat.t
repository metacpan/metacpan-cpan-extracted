#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 9;

use_ok('Media::Convert::Asset');
use_ok('Media::Convert::Asset::Concat');
use_ok('Media::Convert::Pipe');

my $input1 = Media::Convert::Asset->new(url => "t/testvids/bbb.mp4");
ok(defined($input1), "Creating an asset works");
my $input2 = Media::Convert::Asset->new(url => "t/testvids/bbb.mp4");
ok(defined($input2), "Creating a second asset with the same URL works");
my $concat = Media::Convert::Asset::Concat->new(url => "./concat.txt", components => [$input1, $input2]);
ok(defined($concat), "Creating a concat asset works");
isa_ok($concat, "Media::Convert::Asset");
isa_ok($concat, "Media::Convert::Asset::Concat");
my $output = Media::Convert::Asset->new(url => "./test.mkv");

Media::Convert::Pipe->new(inputs => [$concat], output => $output, vcopy => 1, acopy => 1)->run;

my $check = Media::Convert::Asset->new(url => $output->url);

ok(int($check->duration) == int($input1->duration * 2), "The output video has approximately the correct length");

unlink($concat->url);
unlink($output->url);
