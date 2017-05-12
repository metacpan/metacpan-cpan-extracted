use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{};
ok $hr->set( snacks => 'tasty') == $hr, 'boxed set returned self';
ok $hr->get('snacks') eq 'tasty', 'boxed set ok';

$hr->set( a => 1, b => 2, c => 3 );
is_deeply
  +{ $hr->export },
  +{ a => 1, b => 2, c => 3, snacks => 'tasty' },
  'boxed multi-key set ok';

done_testing;
