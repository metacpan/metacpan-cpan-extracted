use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';
my $hr = hash(foo => 1, baz => undef);
ok $hr->defined('foo'), 'defined ok';
ok !$hr->defined('baz'), 'negative defined ok';
ok !$hr->defined('bar'), 'nonexistant defined ok';

done_testing;
