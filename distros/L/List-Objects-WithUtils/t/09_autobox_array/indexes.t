use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

ok ![]->indexes(sub { 1 })->has_any, 'boxed empty indexes ok';

my $arr = [qw/foo bar baz/];

my $idx = $arr->indexes(sub { $_ eq 'bar' });

is_deeply [ $idx->all ], [ 1 ],
  'boxed indexes (single) ok';

is_deeply [ $idx->all ], [ $arr->indices(sub { $_ eq 'bar' })->all ],
  'boxed indices alias ok';

$arr = [ 1 .. 10 ];
$idx = $arr->indexes(sub { $_ % 2 == 0 });

is_deeply [ $idx->all ], [ 1, 3, 5, 7, 9 ],
  'boxed indexes (multiple) ok';

$idx = $arr->indexes;
is_deeply [ $idx->all ], [ 0 .. 9 ],
  'boxed indexes (no arguments) ok';

done_testing
