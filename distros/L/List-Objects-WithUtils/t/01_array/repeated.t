use Test::More;
use strict; use warnings;

use Lowu 'array';

my $arr = array( 'a', 'b', 'c', 'b', 'e', 'c', 'b' );
my $rep = $arr->repeated;
is_deeply [ $rep->sort->all ], [qw/b c/], 'repeated ok';

$rep = array('a', 'b', 'c')->repeated;
ok $rep->is_empty, 'repeated with zero repeats ok';

ok array->repeated->is_empty, 'repeated on empty array ok';

done_testing
