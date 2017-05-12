use strict;
use warnings;

use Test::More;
use Linux::CPUAffinity;

my $ret = Linux::CPUAffinity->get(0);
ok scalar @$ret;
Linux::CPUAffinity->set(0, [0]);
$ret = Linux::CPUAffinity->get(0);
is_deeply $ret, [0];

done_testing;
