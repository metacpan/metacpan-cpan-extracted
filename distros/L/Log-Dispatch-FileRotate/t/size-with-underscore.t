#!/usr/bin/env perl

use strict;
use warnings;
use Test::More 0.88;
use Path::Tiny 0.018;

use_ok 'Log::Dispatch';
use_ok 'Log::Dispatch::FileRotate';

my $tempdir = Path::Tiny->tempdir;

for my $size ('20_000', 20_000) {
    my $logger = Log::Dispatch::FileRotate->new(
        filename    => $tempdir->child('error.log')->stringify,
        min_level   => 'debug',
        mode        => 'append',
        size        => '20_000');

    isa_ok $logger, 'Log::Dispatch::FileRotate';

    cmp_ok $logger->{size}, '==', 20000;
}

done_testing;
