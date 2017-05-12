#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Games::Cards::ShuffleTrack' ) || print "Bail out!\n";
}

diag( "Testing Games::Cards::ShuffleTrack $Games::Cards::ShuffleTrack::VERSION, Perl $], $^X" );
