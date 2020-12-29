#!perl -T

use warnings;
use strict;
use Test::More tests => 1;

use List::Cycle;

pass( 'All modules loaded' );

diag( "Testing List::Cycle $List::Cycle::VERSION, Perl $], $^X" );
diag( "Using Test::More $Test::More::VERSION" );

done_testing();
