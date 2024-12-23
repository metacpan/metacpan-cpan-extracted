#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

use_ok("Media::Convert::Asset");
use_ok("Media::Convert::Map");
use_ok("Media::Convert::Pipe");

my $asset = Media::Convert::Asset->new(url => "t/testvids/bbb.mp4");
my $map = Media::Convert::Map->new(input => $asset, type => "channel", choice => "left");
my $output = Media::Convert::Asset->new(url => "./test.mp4", audio_codec => "aac");

eval {
        my $pipe = Media::Convert::Pipe->new(inputs => [$asset], map => [$map], output => $output, vcopy => 1, acopy => 0);
        $pipe->run;
};
if($@) {
        fail("running a map failed");
} else {
        pass("running a map succeeded");
}

unlink("test.mp4");

done_testing;
