use strict;
use warnings;

use Test::More      0.88                            ;
use Test::Warn      0.23                            ;
use Test::Exception 0.31                            ;


lives_ok { eval q{ use Debuggit DEBUG => 2 } } 'basic sanity check: starting out with DEBUG 2';

warning_is
{
    lives_ok { eval q{ use Debuggit DEBUG => 2 } } 'reimport is okay';
}
    undef, 'no redefine warnings';

warning_like
{
    lives_ok { eval q{ use Debuggit DEBUG => 3 } } 'reimport is okay';
}
    qr/original value.*used/, 'warning when attempting to redefine with a different value';


done_testing;
