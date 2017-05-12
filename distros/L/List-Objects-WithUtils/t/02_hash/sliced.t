use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hr = hash(a => 1, b => 2, c => 3, d => 4);
my $slice = $hr->sliced('a', 'c', 'z');
ok $slice->keys->count == 2, 'sliced key count ok'
  or diag explain $slice;

ok $slice->get('a') == 1, 'sliced get ok';

ok !$slice->exists('z'), 'nonexistant key ignored';
ok !$slice->get('b'), 'unspecified key ignored';

is_deeply
  +{ $slice->export },
  +{ $hr->slice(qw/a c z/)->export },
  'slice alias ok';

done_testing;
