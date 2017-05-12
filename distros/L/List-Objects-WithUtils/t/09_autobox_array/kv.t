use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [qw/foo bar baz quux/];

is_deeply
  [ $arr->kv->all ],
  [
    [ 0 => 'foo' ],
    [ 1 => 'bar' ],
    [ 2 => 'baz' ],
    [ 3 => 'quux' ],
  ],
  'boxed array kv ok';

done_testing;
