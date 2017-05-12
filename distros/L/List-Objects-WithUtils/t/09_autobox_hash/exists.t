use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{foo => 1, baz => 2};
ok $hr->exists('foo'), 'boxed exists ok';
ok !$hr->exists('bar'), 'boxed negative exists ok';

done_testing;
