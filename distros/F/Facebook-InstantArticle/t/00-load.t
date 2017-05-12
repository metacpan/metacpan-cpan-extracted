#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    use_ok( 'Facebook::InstantArticle' ) || print "Bail out!\n";
}

diag( "Testing Facebook::InstantArticle $Facebook::InstantArticle::VERSION, Perl $], $^X" );

done_testing;
