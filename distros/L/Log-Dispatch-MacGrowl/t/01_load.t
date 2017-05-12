#

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Log::Dispatch::MacGrowl');
}

diag( "Testing Log::Dispatch::MacGrowl $Log::Dispatch::MacGrowl::VERSION" );

if( eval "use Cocoa::Growl; 1" ){
    diag( "we have Cocoa::Growl." );
}
elsif( eval "use Growl::Tiny; 1" ){
    diag( "we have Growl::Tiny." );
}
elsif( eval "use Mac::Growl; 1" ){
    diag( "we have Mac::Growl." );
}
else{
    diag( "we have no growl backend modules. all tests may fail." );
}
