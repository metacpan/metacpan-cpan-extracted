use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{a => 1, b => 2, c => 3, d => 4};
my $slice = $hr->sliced('a', 'c', 'z');
ok $slice->keys->count == 2, 'boxed sliced key count ok';

ok $slice->get('a') == 1, 'sliced get ok';

ok !$slice->exists('z'), 'nonexistant key ignored';
ok !$slice->get('b'), 'unspecified key ignored';

done_testing;
