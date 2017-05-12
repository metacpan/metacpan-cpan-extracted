#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok 'MIDI::Drummer::Tiny';
}

diag("Testing MIDI::Drummer::Tiny $MIDI::Drummer::Tiny::VERSION, Perl $], $^X");

done_testing();
