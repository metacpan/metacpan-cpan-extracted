use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $first  = [ qw/ a b c d e / ];
my $second = array( qw/ c d x y / );
my $third  = [ qw/ a b c d e f g / ];

my $intersects = $first->intersection($second, $third);
ok $intersects->count == 2, '2 items in intersection'
  or diag explain $intersects;
is_deeply
  [ $intersects->sort->all ],
  [ qw/ c d / ],
  'boxed intersection looks ok'
    or diag explain $intersects;

done_testing
