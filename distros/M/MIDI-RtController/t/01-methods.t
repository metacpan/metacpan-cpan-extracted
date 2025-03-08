#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::RtController';

# skip live testing
# my $obj = new_ok 'MIDI::RtController' => [
#    input  => 'foo',
#    output => 'fluid',
#];

done_testing();
