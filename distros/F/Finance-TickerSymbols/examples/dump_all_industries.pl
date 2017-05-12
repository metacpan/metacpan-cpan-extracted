

use lib '../lib' ;
use lib 'lib' ;
use Finance::TickerSymbols ;

local $, = "\n    " ;
for my $ind ( sort {$a cmp $b} industries_list() ) {
    print $ind, ( sort {$a cmp $b} industry_list( $ind ) ), "\n"
}




