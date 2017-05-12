use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{ foo => 1, bar => 2 };
my $copy = $hr->copy;
ok $copy->get('foo') == 1, 'boxed copy ok';

done_testing;
