use strict;
use warnings;
use Test::More tests => 12;
use Forks::Super;
use Signals::XSIG;

Forks::Super::Debug::use_Carp_Always();

alarm(10);
$SIG{ALRM} = sub { die "Timeout\n" };

diag "initial init";
ok($XSIG{CHLD} && $XSIG{CHLD}[-1], # && !$XSIG{CHLD}[0],
   'init: FS SIGCHLD handler set');

my $pid = fork { sub => sub {
    sleep 3;
    diag "init: child exiting";
    exit;
                 } };
ok(Forks::Super::Job::count_active_processes() > 0,
   'init: active process registered in FSJ');
my $wpid = eval { waitpid $pid,0; };
if ($@) {
    my $z = kill 'TERM', $pid+0;
    alarm(2);
    $wpid = eval { CORE::waitpid $pid,0 };
    alarm(0);
    if ($wpid) { Forks::Super::Wait::_reap() }
    print STDERR "waitpid $pid failed: $@  \$z=$z, 2nd waitpid=$wpid\n";
}
ok($wpid == $pid, 'init: waitpid retrieved job');

my $n = 0;
Forks::Super::Util::set_productive_pause_code( sub { $n += 10 } );
Forks::Super::Util::pause(0.5);
ok($n > 0, 'init: productive pause code active');

diag "deinit";
Forks::Super->deinit_pkg;
alarm(10);

$n = 0;
Forks::Super::Util::pause(0.5);
ok($n == 0, 'deinit: productive pause code inactive');
ok(!$XSIG{CHLD} || !$XSIG{CHLD}[-1], 'deinit: FS SIGCHLD handler disabled');
$pid = fork;
if ($pid == 0) {
    sleep 2;
    diag "deinit: child exiting";
    exit;
}
ok(Forks::Super::Job::count_active_processes() == 0,
   'deinit: active process not registered in FSJ');
$wpid = waitpid $pid,0;
ok($wpid == $pid, 'deinit: waitpid retrieved job');

diag "reinit";
Forks::Super->init_pkg;
alarm(10);

$pid = fork();
if ($pid == 0) {
    sleep 3;
    diag "reinit: child exiting";
    exit;
}
ok(Forks::Super::Job::count_active_processes() > 0,
   'reinit: active process registered in FSJ');
$wpid = eval { waitpid $pid,0 };
if ($@) {
    my $e1 = $@;
    my $z = kill 'TERM', $pid+0;
    alarm(2);
    $wpid = eval { CORE::waitpid $pid,0 };
    alarm(0);
    if ($wpid) { Forks::Super::Wait::_reap() }
    print STDERR "waitpid $pid failed: $e1  \$z=$z, 2nd waitpid=$wpid\n";
}
ok($wpid == $pid, 'reinit: waitpid retrieved job');

$n = 0;
Forks::Super::Util::set_productive_pause_code( sub { $n += 10 } );
Forks::Super::Util::pause(0.5);
ok($n > 0, 'reinit: productive pause code active');

ok($XSIG{CHLD} && $XSIG{CHLD}[-1], # && !$XSIG{CHLD}[0],
   'reinit: FS SIGCHLD handler set');
alarm(0);
