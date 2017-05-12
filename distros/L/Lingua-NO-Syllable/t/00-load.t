#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Lingua::NO::Syllable' ) || print "Bail out!\n";
}

diag( "Testing Lingua::NO::Syllable $Lingua::NO::Syllable::VERSION, Perl $], $^X" );

done_testing;
