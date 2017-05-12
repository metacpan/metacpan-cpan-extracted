#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';
BEGIN { use_ok( 'MIDI::Tab' ) }
diag("Testing MIDI::Tab $MIDI::Tab::VERSION, Perl $], $^X");
