#! perl

use strict;
use warnings;

use Test::More;
use Linux::FD::Mem;

my $memfd = Linux::FD::Mem->new('test', 'allow-sealing');

ok $memfd, 'Got a memfd';
is syswrite($memfd, 'Test'), 4, 'Can write to memfd';
ok sysseek($memfd, 0, 0), 'Can seek a memfd';
ok sysread($memfd, my $buffer, 4), 'Can read memfd';
is $buffer, 'Test', 'Got the right result from memfd';

is_deeply([ $memfd->get_seals() ], [], 'No seals set');

$memfd->seal('write');

is_deeply([ $memfd->get_seals() ], ['write'], 'Write seal set');

$memfd->seal('seal');

is_deeply([ sort $memfd->get_seals() ], ['seal', 'write'], 'Write and seal seal set');

is eval { $memfd->seal('grow') }, undef, 'Further sealing gives an error';

done_testing;
