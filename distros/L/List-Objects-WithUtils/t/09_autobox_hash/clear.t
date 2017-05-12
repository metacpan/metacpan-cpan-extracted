use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = [foo => 1, bar => 2];
ok $hr->clear == $hr, 'boxed clear returned self';
ok $hr->is_empty, 'boxed clear ok';

done_testing;
