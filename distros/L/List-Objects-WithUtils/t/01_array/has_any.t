use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array;
ok !$arr->has_any, 'negative bare has_any ok';
$arr->push(qw/ a b c /);
ok $arr->has_any, 'bare has_any ok';
ok $arr->has_any(sub { /b/ }), 'has_any ok';
ok !$arr->has_any(sub { /d/ }), 'negative has_any ok';

ok array(1, 2, undef)->has_any(sub { !defined }),
  'has_any search for undef ok';

done_testing;
