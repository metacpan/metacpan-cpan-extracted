use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

ok !array->indexes(sub { 1 })->has_any, 'empty indexes ok';

my $arr = array(qw/foo bar baz/);

my $idx = $arr->indexes(sub { $_ eq 'bar' });

is_deeply [ $idx->all ], [ 1 ],
  'indexes (single) ok';

is_deeply [ $idx->all ], [ $arr->indices(sub { $_ eq 'bar' })->all ],
  'indices alias ok';

$arr = array( 1 .. 10 );
$idx = $arr->indexes(sub { $_ % 2 == 0 });

is_deeply [ $idx->all ], [ 1, 3, 5, 7, 9 ],
  'indexes (multiple) ok';

$idx = $arr->indexes;
is_deeply [ $idx->all ], [ 0 .. 9 ],
  'indexes (no arguments) ok';

done_testing
