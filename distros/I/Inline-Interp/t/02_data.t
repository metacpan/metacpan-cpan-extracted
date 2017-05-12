use strict;
use Test::More tests => 2;

use Inline 'Echo';

is(fna({echo => 0}), 'this', 'fna()');
is(fnb({echo => 0}), 'is a test', 'fna()');

__END__
__Echo__
function fna {this}
function fnb {is a test}
