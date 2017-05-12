#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
BEGIN {
    use_ok 'MIDI::Simple::Drummer';
    use_ok 'MIDI::Simple::Drummer::Rock';
    use_ok 'MIDI::Simple::Drummer::Jazz';
    use_ok 'MIDI::Simple::Drummer::Rudiments';
}
diag "MIDI::Simple::Drummer $MIDI::Simple::Drummer::VERSION, Perl $], $^X";
done_testing();
