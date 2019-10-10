use strict;
use warnings;

use Test::More;
use MP4::LibMP4v2;

eval 'use Test::LeakTrace 0.08';
plan skip_all => "Test::LeakTrace 0.08 required for testing leak trace" if $@;
plan tests => 1;

no_leaks_ok(sub {
    my $filename = 't/SampleVideo_1280x720_1mb.mp4';
    my $mp4 = MP4::LibMP4v2->read($filename);
    $mp4->info;
});
