#!perl -T

use strict;
use warnings;
use Test::More tests => 6;

use Finance::FIX;

# From http://en.wikipedia.org/wiki/Financial_Information_eXchange
my $msg = "8=FIX.4.29=17835=849=PHLX56=PERS52=20071123-05:30:00.00011=ATOMNOCCC999090020=3150=E39=E55=MSFT167=CS54=138=1540=244=1558=PHLX EQUITY TESTING59=047=C32=031=0151=1514=06=010=128";

my $fix   = Finance::FIX->new;
my $nodes = $fix->parse($msg);

ok( $nodes, 'parse() returned something' );
is( scalar @$nodes, 25, 'parse() returned right number of nodes' );
is( $nodes->[0][0],   '8',        "[0][0]   == '8'" );
is( $nodes->[0][1],   'FIX.4.2',  "[0][1]   == 'FIX.4.2'" );
is( $nodes->[24][0],  '10',       "[24][0]  == '10'" );
is( $nodes->[24][1],  '128',      "[24][1]  == '128'" );

