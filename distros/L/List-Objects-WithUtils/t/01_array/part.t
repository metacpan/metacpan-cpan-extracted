use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my ($evens, $odds) = array( 1 .. 6 )->part(sub { $_ & 1 })->all;

is_deeply 
  [ $evens->all ], 
  [ 2,4,6 ], 
  'part() with args picked evens ok';

is_deeply 
  [ $odds->all ], 
  [ 1,3,5 ], 
  'part() with args picked odds ok';

my $parts_n = do {
  my $i = 0;
  array(1 .. 12)->part(sub { $i++ % 3 });
};

ok( $parts_n->count == 3, 'part() created 3 arrays' );

is_deeply
  [ $parts_n->get(0)->all ],
  [ 1, 4, 7, 10 ],
  'part() first array ok';

is_deeply
  [ $parts_n->get(1)->all ],
  [ 2, 5, 8, 11 ],
  'part() second array ok';

is_deeply
  [ $parts_n->get(2)->all ],
  [ 3, 6, 9, 12 ],
  'part() third array ok';

my $parts_single = array(1 .. 12)->part(sub { 3 });

ok( $parts_single->get(0)->count == 0, 'part() 0 empty ok' );
ok( $parts_single->get(1)->count == 0, 'part() 1 empty ok' );
ok( $parts_single->get(2)->count == 0, 'part() 2 empty ok' );

is_deeply
  [ $parts_single->get(3)->all ],
  [ 1 .. 12 ],
  'part() 3 filled ok';



done_testing;
