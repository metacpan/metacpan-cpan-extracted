use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array qw/foo bar baz quux/;

is_deeply
  [ $arr->kv->all ],
  [
    [ 0 => 'foo' ],
    [ 1 => 'bar' ],
    [ 2 => 'baz' ],
    [ 3 => 'quux' ],
  ],
  'array kv ok';

ok array->kv->is_empty, 'empty array kv ok';

done_testing;
