

use strict ;
use warnings ;

use lib '../lib' ;
use lib 'lib' ;
use Finance::TickerSymbols ;
use Finance::YahooQuote ;
$| = 1 ;

for my $symbol (symbols_list 'all') {

    my @Q = getonequote $symbol ;
    print "$Q[1] ($Q[0]) is $Q[2]\n" ;
}



