use strict;
use warnings;
use Test::More;
use POSIX ();
use IO::Select;
use EV;
use EV::Websockets;

use if -d 'blib', lib => 'blib/lib', 'blib/arch';

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Regression: an idle (open but silent) connection must not stall the EV loop.
#
# Previously do_lws_service called lws_service(ctx, 0); a timeout of 0 is not
# non-blocking (lws maps it to its maximum internal poll wait), so it BLOCKED
# for many seconds on an idle connection, freezing every other EV watcher -- a
# repeating user timer stopped firing after ~3s. The fix services lws
# non-blockingly (lws_service_tsi(ctx, -1, 0)).
#
# Because the bug freezes the loop, it cannot be bounded by an in-loop watchdog
# (that watcher freezes too). So we run the scenario in a child and let the
# parent -- which is not in the EV loop -- enforce a hard wall-clock deadline:
# if the child does not report back in time, the loop stalled and we fail fast
# instead of hanging.

pipe(my $r, my $w) or plan skip_all => "pipe: $!";
my $pid = fork;
plan skip_all => "fork unavailable: $!" unless defined $pid;

if (!$pid) {
    # Child: hold an idle connection while a repeating timer must keep firing.
    close $r;
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my $established = 0;
    my $err;

    my $port = $ctx->listen(
        port       => 0,
        on_connect => sub { $keep{server} = $_[0] },
        on_message => sub { },
        on_close   => sub { },
    );
    # Connect, then stay silent so both ends sit idle.
    $keep{client} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub { $established = 1 },
        on_message => sub { },
        on_close   => sub { },
        on_error   => sub { $err = $_[1]; EV::break },
    );

    # 16 ticks at 0.25s is ~4s -- past the old ~3s stall point.
    my $ticks = 0;
    my $tick  = EV::timer(0.25, 0.25, sub { EV::break if ++$ticks >= 16 });
    # Fallback so the child still reports (rather than being killed) if ticks
    # somehow never reach 16 without the loop being frozen.
    my $fallback = EV::timer(9, 0, sub { EV::break });

    EV::run;

    syswrite($w, join(" ", $established, $ticks, defined $err ? "ERR:$err" : "-"));
    close $w;
    POSIX::_exit(0);
}

# Parent: not in the EV loop, so it can bound the child. Healthy ~4s; kill at 12s.
#
# Two very different "no result" cases must not be conflated:
#   * the deadline passes with the pipe silent -> the loop really is stalled
#     (this is the regression being guarded), so fail;
#   * EOF, i.e. the child exited before reporting -> says nothing about the
#     loop, and happens occasionally on loaded machines. Report the child's
#     exit status and skip rather than raise a false failure.
close $w;
my ($established, $ticks, $err) = (0, 0, undef);
my ($got_result, $timed_out) = (0, 0);
{
    # can_read() also returns empty when select() is interrupted (EINTR) -- and
    # the child writing its result then exiting delivers SIGCHLD, which does
    # exactly that. Treating an interrupt as a timeout reported a bogus "loop
    # STALLED" while the result sat unread in the pipe, so retry while time
    # remains and only call it a timeout once the deadline has really passed.
    my $sel      = IO::Select->new($r);
    my $deadline = time + 12;
    while (1) {
        my $remaining = $deadline - time;
        if ($remaining <= 0) { $timed_out = 1; last }
        unless ($sel->can_read($remaining)) {
            next if time < $deadline;   # interrupted, not expired
            $timed_out = 1;
            last;
        }
        my $n = sysread($r, my $buf, 256);
        next if !defined $n && $!{EINTR};
        last if !defined $n || $n == 0; # EOF: child exited without reporting
        $got_result = 1;
        ($established, $ticks, my $e) = split ' ', $buf, 3;
        $err = $1 if defined $e && $e =~ /^ERR:(.*)/s;
        last;
    }
    kill 'KILL', $pid if $timed_out;
}
close $r;
waitpid $pid, 0;
my $child_status = $?;

SKIP: {
    skip sprintf("child exited without reporting (status 0x%04x%s); cannot judge the loop",
                 $child_status,
                 ($child_status & 127) ? ", signal " . ($child_status & 127) : ""), 2
        if !$got_result && !$timed_out;

    skip "connection failed: $err", 2 if $err && !$established;

    ok($got_result && $established,
        $timed_out ? "EV loop STALLED on idle connection (no result within deadline)"
                   : "idle connection established");
    cmp_ok($ticks, '>=', 16,
        "user timer kept firing while connection idled ($ticks ticks; "
        . "the pre-fix loop stall capped this far lower)");
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
