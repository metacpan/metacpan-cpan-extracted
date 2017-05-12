use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 3 );
my $mapval = $arr->mapval(sub { ++$_ });
is_deeply
  [ $mapval->all ],
  [ 2, 3, 4 ],
  'mapval ok';

is_deeply
  [ $arr->all ],
  [ 1, 2, 3 ],
  'original intact';

$mapval = $arr->mapval(sub { $_[0]++ });
is_deeply
  [ $mapval->all ],
  [ 2, 3, 4 ],
  'mapval on $_[0] ok';


ok array->mapval(sub { 1 })->is_empty, 'empty array mapval ok';


done_testing;
