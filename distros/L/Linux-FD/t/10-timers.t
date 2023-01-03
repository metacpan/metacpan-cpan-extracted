# perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;
use Linux::FD 'timerfd';
use Linux::FD::Timer;
use IO::Select;
use Time::HiRes qw/sleep/;

my $selector = IO::Select->new;

alarm 2;

my $fd = timerfd('realtime', 'non-blocking');
$selector->add($fd);

ok !$selector->can_read(0), 'Can\'t read an empty timerfd';

ok !defined $fd->receive, 'Can\'t read an empty signalfd directly';

$fd->set_timeout(0.1);

sleep 0.2;

ok $selector->can_read(0), 'Can read an triggered timerfd';

ok $fd->receive, 'Got timeout';

ok !$selector->can_read(0), 'Can\'t read an received timerfd';

$fd->set_timeout(0.1, 0.1);

my ($value, $interval) = $fd->get_timeout;

cmp_ok $value, '<=', 0.1, 'Value is right';
ok 0.099 < $interval && $interval < 0.101, 'Interval is right';

sleep 0.21;

is $fd->receive, 2, 'Got two timeouts';

my %clocks = map { $_ => 1 } Linux::FD::Timer->clocks;

ok $clocks{monotonic}, 'Has monotonic clock';
ok $clocks{realtime}, 'Has realtime clock';

done_testing;
