use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $first  = array( qw/ a b c d e / );
my $second = array( qw/ c d x y / );
my $third  = [ qw/ a b c d e f g / ];

my $intersects = $first->intersection($second, $third);
ok $intersects->count == 2, '2 items in intersection'
  or diag explain $intersects;
is_deeply
  [ $intersects->sort->all ],
  [ qw/ c d / ],
  'intersection looks ok'
    or diag explain $intersects;

$intersects = $first->intersection($second);
ok $intersects->count == 2, '2 items in intersection';
is_deeply
  [ $intersects->sort->all ],
  [ qw/ c d / ],
  'intersection (one array) looks ok';

ok $first->intersection( [ 1, 2, 3 ] )->is_empty,
  'empty intersection ok';

my $dupes = array( qw/ z z c d / );
$intersects = $dupes->intersection($first);
is_deeply
  [ $intersects->sort->all ],
  [ qw/ c d / ],
  'intersection (dupes in one array) ok';

ok array->intersection(array)->is_empty,
  'empty array(s) intersection ok';

done_testing
