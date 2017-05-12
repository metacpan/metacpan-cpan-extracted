use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

ok !defined []->random, 'boxed empty array random returned undef';

my $arr = [qw/ foo bar /];
my $random = $arr->random;
ok $random eq 'foo' || $random eq 'bar',
  'boxed random() ok';

done_testing;
