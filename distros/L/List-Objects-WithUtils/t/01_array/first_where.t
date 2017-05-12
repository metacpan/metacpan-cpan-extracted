use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(qw/ a ba bb c /);

my $first = $arr->first_where(sub { /^b/ });

ok $first eq 'ba', 'first_where ok';

ok $arr->first(sub { /^b/ }) eq $first,
  'backwards compat ok';


ok !defined array->first_where(sub { 1 }),
  'first_where on empty array returns undef';

done_testing;
