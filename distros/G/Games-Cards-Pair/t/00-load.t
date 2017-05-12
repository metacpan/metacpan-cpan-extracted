#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN {
    use_ok('Games::Cards::Pair')         || print "Bail out!\n";
    use_ok('Games::Cards::Pair::Card')   || print "Bail out!\n";
    use_ok('Games::Cards::Pair::Params') || print "Bail out!\n";
}

diag( "Testing Games::Cards::Pair $Games::Cards::Pair::VERSION, Perl $], $^X" );
