use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 10 );

my $pair = $arr->bisect(sub { $_ >= 5 });

isa_ok $pair, 'List::Objects::WithUtils::Array',
  'bisect returned array obj';

ok $pair->count == 2, 'bisect() returned two items';
isa_ok $pair->get(0), 'List::Objects::WithUtils::Array';
isa_ok $pair->get(1), 'List::Objects::WithUtils::Array';

is_deeply [ $pair->get(0)->all ], [ 5 .. 10 ];
is_deeply [ $pair->get(1)->all ], [ 1 .. 4 ];

ok array()->bisect(sub {})->count == 2, 'bisect always returns two arrays';

done_testing;
