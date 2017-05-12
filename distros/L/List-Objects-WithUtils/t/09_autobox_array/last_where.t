use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [qw/ a ba bb c /];

ok $arr->last_where(sub { /^a$/ }) eq 'a', 'boxed last_where ok';
ok !$arr->last_where(sub { /d/ }), 'boxed negative last_where ok';

ok !defined []->last_where(sub { 1 }),
  'boxed last_where on empty array returned undef';

done_testing;
