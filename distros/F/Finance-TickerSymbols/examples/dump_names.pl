

use lib '../lib' ;
use lib 'lib' ;
use Finance::TickerSymbols ;

$Finance::TickerSymbols::long = 1 ; # symbol:full name

local $, = "\n" ;

warn "usage:\n $0 nasdaq|nyse|amex|all\n" unless @ARGV ;

for my $market (@ARGV) {
    print ":: $market ::",
      sort (symbols_list( $market )) ,
        '' ;
}



