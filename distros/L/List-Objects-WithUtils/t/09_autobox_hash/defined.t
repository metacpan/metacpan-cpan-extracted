use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{foo => 1, baz => undef};
ok $hr->defined('foo'), 'boxed defined ok';
ok !$hr->defined('baz'), 'boxed negative defined ok';
ok !$hr->defined('bar'), 'boxed nonexistant defined ok';

done_testing;
