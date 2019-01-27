#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::Drummer::Tiny';

my $d = new_ok 'MIDI::Drummer::Tiny';

isa_ok $d->score, 'MIDI::Simple';

is $d->beats, 4, 'beats computed';
is $d->divisions, 4, 'divisions computed';

is(($d->score->Score)[1][0], 'time_signature', 'time signature added');

done_testing();
