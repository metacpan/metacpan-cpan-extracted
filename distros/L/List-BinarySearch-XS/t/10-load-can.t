#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok( 'List::BinarySearch::XS', qw( :all ) )
        || BAIL_OUT();
}

diag( "Testing List::BinarySearch::XS " .
      "$List::BinarySearch::XS::VERSION, Perl $], $^X"
);


can_ok(
    'List::BinarySearch::XS',
    qw( binsearch binsearch_pos )
);

done_testing();
