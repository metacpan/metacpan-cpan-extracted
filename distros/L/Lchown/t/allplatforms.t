use strict;
use warnings;

use Test::More (tests => 2);

BEGIN { use_ok('Lchown') }

ok( !lchown(9,9,"nosuchfile"), "failed on nonexistent file" );

