#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::Drummer::Tiny';

my $md = MIDI::Drummer::Tiny->new(
);
isa_ok $md, 'MIDI::Drummer::Tiny';

is $md->beats, 4, 'beats';
is $md->divisions, 4, 'divisions';

done_testing();
