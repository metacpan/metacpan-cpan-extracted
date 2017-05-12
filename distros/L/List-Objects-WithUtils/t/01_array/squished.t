use Test::More;
use strict; use warnings;

use Lowu 'array';

my $arr = array(qw/a b b c d c c e b/);
my $squished = $arr->squished;
is_deeply [ $squished->all ], [ qw/a b c d c e b/ ], 'squished ok';
is_deeply [ $arr->squish->all ], [ $squished->all ], 'squish alias ok';

$arr = array('a', 'b', undef, 'b', undef, undef, 'c');
is_deeply [ $arr->squished->all ], [ 'a', 'b', undef, 'b', undef, 'c' ],
  'squished with (middle) undefs ok';

$arr = array(undef, undef, 'a', 'b');
is_deeply [ $arr->squished->all ], [ undef, 'a', 'b' ],
  'squished with (leading) undefs ok';

$arr = array(undef, 'a', 'a', 'b');
is_deeply [ $arr->squished->all ], [ undef, 'a', 'b' ],
  'squished with leading single undef ok';

$arr = array('a', 'b', 'c');
is_deeply [ $arr->squished->all ], [ 'a', 'b', 'c' ],
  'squished (no squished values) ok';

ok array->squished->is_empty, 'squished on empty array ok';

done_testing
