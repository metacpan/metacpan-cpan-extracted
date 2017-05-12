use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [qw/ a ba bb c /];

my $first = $arr->first_where(sub { /^b/ });
ok $first eq 'ba', 'boxed first_where ok';
ok !defined []->first_where(sub { 1 }),
  'boxed first_where on empty array returns undef';

done_testing;
