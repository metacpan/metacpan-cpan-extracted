#!/run/bin/perl 

use lib qw{
          lib
       ../lib
    ../../lib
};

use Test::More 'no_plan';

diag( 
    q*Executing user tests.*
);
diag( 
    q*Full test suite available in t/all/*, 
    q* requires perl 5.010 and all 'recommends' modules.* 
);

pass();

