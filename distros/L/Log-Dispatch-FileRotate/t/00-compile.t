#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 0.88;

use_ok $_ for qw(
    Log::Dispatch::FileRotate
    Log::Dispatch::FileRotate::Flock
    Log::Dispatch::FileRotate::Mutex
);

done_testing;
