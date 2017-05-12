use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(qw/ a b c d/);

my $meshed = $arr->mesh( array(1, 2, 3, 4) );
is_deeply
  [ $meshed->all ],
  [ a => 1, b => 2, c => 3, d => 4 ],
  'mesh on even lists ok';

$meshed = $arr->mesh([1,2]);
is_deeply
  [ $meshed->all ],
  [ 'a', 1, 'b', 2, 'c', undef, 'd', undef ],
  'mesh on uneven lists ok';

my @holey; $#holey = 9;
$meshed = array( 1 .. 10 )->mesh( array(@holey) );
is_deeply
  [ $meshed->all ],
  [
    1, undef, 2, undef, 3, undef, 4, undef, 5, undef,
    6, undef, 7, undef, 8, undef, 9, undef, 10, undef
  ],
  'mesh with undef-filled list ok';

my @first  = ( 1, 2 );
my @second = qw/ foo bar baz/;
$meshed = array( 'x' )->mesh( array(@first), \@second );
is_deeply
  [ $meshed->all ],
  [ 'x', 1, 'foo', undef, 2, 'bar', undef, undef, 'baz' ],
  'mesh on mixed object/ref arrays ok';

eval {; array('foo')->mesh('bar') };
ok $@ =~ /ARRAY/, 'mesh with bad args dies'
  or diag explain $@;

ok array->mesh([], [])->is_empty,
  'meshing empty arrays ok';

ok array->zip([], [])->is_empty, 'zip alias for mesh ok';

done_testing;
