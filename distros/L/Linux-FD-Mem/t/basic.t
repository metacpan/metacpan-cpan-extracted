#! perl

use strict;
use warnings;

use Test::More;
use Linux::FD::Mem;

my $memfd = Linux::FD::Mem->new("test");

ok $memfd, 'Got a memfd';
is syswrite($memfd, 'Test'), 4, 'Can write to memfd';
ok sysseek($memfd, 0, 0), 'Can seek a memfd';
ok sysread($memfd, my $buffer, 4), 'Can read memfd';
is $buffer, 'Test', 'Got the right result from memfd';

done_testing;
