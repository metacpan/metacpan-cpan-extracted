use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 3 ];
my $mapval = $arr->mapval(sub { ++$_ });
is_deeply
  [ $mapval->all ],
  [ 2, 3, 4 ],
  'boxed mapval ok';
is_deeply
  [ $arr->all ],
  [ 1, 2, 3 ],
  'original intact';

$mapval = $arr->mapval(sub { $_[0]++ });
is_deeply
  [ $mapval->all ],
  [ 2, 3, 4 ],
  'boxed mapval on $_[0] ok';

ok []->mapval(sub { 1 })->is_empty, 'boxed empty array mapval ok';


done_testing;
