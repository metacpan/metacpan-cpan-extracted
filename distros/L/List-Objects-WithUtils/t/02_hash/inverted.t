use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash', 'array';

my $hr = hash(
  a => 1,
  b => 1,
  c => 2,
  d => 3,
);

my $inv = $hr->inverted;
ok $inv->keys->count == 3, 'correct key count in inverted hash'
  or diag explain $hr;
for my $idx (1,2,3) {
  ok $inv->get($idx)->does('List::Objects::WithUtils::Role::Array'),
    "key $idx isa array obj";
  ok $inv->get($idx)->has_any, "key $idx has elements";
}

is_deeply
  +{ map {; $_ => 1 } $inv->get(1)->all },
  +{ map {; $_ => 1 } qw/a b/ },
  'inverted multiples ok';

is_deeply
  [ $inv->get(2)->export ],
  [ 'c' ],
  'inverted single ok';

is_deeply
  [ $inv->get(3)->export ],
  [ 'd' ],
  'inverted single ok (2)';

done_testing
