

use lib '../lib' ;
use lib 'lib' ;
use Finance::TickerSymbols ;

my $ind = shift or die "usage: $0 'valid industry name'\n" ;

$Finance::TickerSymbols::long = 1 ;

local $, = "\n" ;
print sort {$a cmp $b} industry_list( $ind ) ;
print "\n" ;


