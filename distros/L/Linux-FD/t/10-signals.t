# perl -T

use strict;
use warnings FATAL => 'all';

use Test::More 0.89;
use Test::Exception;

use Linux::FD 'signalfd';
use IO::Select;
use POSIX qw/sigprocmask SIGUSR1 SIG_SETMASK/;

my $selector = IO::Select->new;

alarm 2;

my $sigset = POSIX::SigSet->new();
$sigset->addset(SIGUSR1);

sigprocmask(SIG_SETMASK, $sigset) or bailout('Can\'t set signal-mask');

my $fd = signalfd($sigset);
$fd->blocking(0);
$selector->add($fd);

ok !$selector->can_read(0), 'Can\'t read an empty signalfd';

ok !defined $fd->receive, 'Can\'t read an empty signalfd directly';

ok kill(SIGUSR1, $$), 'Not killed by sigusr1';

ok $selector->can_read(0), 'Can read signalfd after signal delivery';

my $sig_info = $fd->receive;

is $sig_info->{signo}, SIGUSR1, 'Received SIGUSR1';

ok !$selector->can_read(0), 'Can\'t read signalfd after signal reception';

lives_ok { signalfd(SIGUSR1) } 'signalfd accepts signal number';
lives_ok { signalfd('USR1') } 'signalfd accepts signal name';

done_testing;
