use Test;
BEGIN { plan tests => 3 }

use Event::Lib;
use Devel::Peek;

ok(1); 

use POSIX;

my $pid = fork;
skip($!, 1) if not defined $pid;

if ($pid) {
    # so the child can call event_init()
    sleep 1;
    kill SIGHUP => $pid;
    ok(1);
    wait;
} else {
    event_init;
    signal_new(SIGHUP, sub { ok(1); exit; })->add;
    
    # we give it ten seconds to receive the signal
    event_one_loop(10);
    ok(0);
    exit;
}


