
BEGIN {
  unless (
    eval {; require List::Objects::Types; 1 } && !$@
    && eval {; require Types::Standard; 1 }   && !$@
  ) {
    require Test::More;
    Test::More::plan(skip_all =>
      'these tests require List::Objects::Types and Types::Standard'
    );
  }
}

# also see t/01_array/tuples.t

use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::Types -all;
use Types::Standard -all;

use List::Objects::WithUtils 'array';

my $arr = array(qw/ foo bar baz quux /);
my $tuples = $arr->tuples(2 => Str);
is_deeply
  [ $tuples->all ],
  [ [ foo => 'bar' ], [ baz => 'quux' ] ],
  'tuples with Str check ok';

eval {; $tuples = $arr->tuples(2, Int) };
ok $@ =~ /type/i, 'Int check failed with type err'
  or diag explain $@;

$arr = array( [], [], [], [] );
$tuples = $arr->tuples(2, ArrayObj);
ok $tuples->shift->[0]->count == 0, 'ArrayObj coerced in tuple';

$arr = immarray(1.4, 1.6, 2.1, 2.2, 2.5);
$tuples = $arr->tuples(2, Int->plus_coercions(Num, sub { int }));
ok $tuples->is_immutable, 'tuples on immutable list produced immutable list';
is_deeply [ $tuples->all ],
  [ [1,1], [2,2], [2] ],
  'type coercion on uneven tuples ok';

eval {; $tuples = $arr->tuples(3, 'foo') };
ok $@ =~ /Type::Tiny/, 'bad type dies ok';

{ use Lowu;
  $tuples = [ 1 .. 4 ]->tuples(2, Int);
  is_deeply
    [ $tuples->all ],
    [ [ 1, 2 ], [ 3, 4 ] ],
    'autoboxed ->tuples ok';
}

done_testing;
