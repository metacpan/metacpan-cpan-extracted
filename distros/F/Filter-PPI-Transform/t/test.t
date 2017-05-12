use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin";

BEGIN { use_ok('Test') }

is(Test::func1_(), 'func1');
is(Test::func2_(), 'func2');
