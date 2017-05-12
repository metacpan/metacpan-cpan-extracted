

use lib '../lib' ;
use lib 'lib' ;
use Finance::TickerSymbols ;

local $, = "\n" ;

print sort {$a cmp $b} industries_list() ;
print "\n" ;


