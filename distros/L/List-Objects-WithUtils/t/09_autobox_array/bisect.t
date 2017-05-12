use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 10 ];

my $pair = $arr->bisect(sub { $_ >= 5 });

isa_ok $pair, 'List::Objects::WithUtils::Array',
  'boxed bisect returned array obj';

ok $pair->count == 2, 'boxed bisect() returned two items';
isa_ok $pair->get(0), 'List::Objects::WithUtils::Array';
isa_ok $pair->get(1), 'List::Objects::WithUtils::Array';

is_deeply [ $pair->get(0)->all ], [ 5 .. 10 ];
is_deeply [ $pair->get(1)->all ], [ 1 .. 4 ];

ok []->bisect(sub {})->count == 2,
  'boxed bisect on empty array ok';

done_testing;
