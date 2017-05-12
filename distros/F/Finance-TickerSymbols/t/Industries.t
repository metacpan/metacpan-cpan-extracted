
use strict ;

use Test::More tests => 5 ;
BEGIN { use_ok('Finance::TickerSymbols') };

my @inds = industries_list() ;
ok(@inds > 100 ) ;

for my $ind (@inds[20, 30, 40]) {
    ok( industry_list( $ind ))
}
