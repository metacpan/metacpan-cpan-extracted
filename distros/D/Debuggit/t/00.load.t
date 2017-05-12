use strict;
use warnings;

use Test::More      0.88                            ;
use Test::Exception 0.31                            ;


BEGIN { use_ok( 'Debuggit' ); }

lives_ok { debuggit("just testing") } "debuggit function is defined";


done_testing;
