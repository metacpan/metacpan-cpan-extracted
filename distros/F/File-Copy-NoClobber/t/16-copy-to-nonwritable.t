#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;
use Test::Warnings;

use File::Copy::NoClobber;

SKIP: {

    skip "/ isn't a dir or we're on windows", 1, if !-d "/" or $^O =~/win/i;

    throws_ok { copy("something", "/") }
        qr/Destination.*not writable/,
        "doesn't try to copy to nonwritable locations";

}

done_testing;
