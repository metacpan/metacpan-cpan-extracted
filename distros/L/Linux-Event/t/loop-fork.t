use v5.36;
use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use Fcntl qw(F_GETFL O_NONBLOCK);
use POSIX ();
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::TTY;
use Linux::Event::Kernel::Inotify;
use Linux::Event::Kernel::Timer;

sub child_exit ($ok) {
    POSIX::_exit($ok ? 0 : 1);
}

sub reap_ok ($pid, $name) {
    is(waitpid($pid, 0), $pid, "$name child reaped");
    is($? >> 8, 0, "$name child succeeded");
}

{
    my $loop = Linux::Event::Loop->new;
    $loop->run_once(0);
    is($loop->stats->{run_once_calls}, 1,
        'parent has diagnostic history before fork');
    my $pid = $loop->fork;
    if ($pid == 0) {
        child_exit($loop->_owner_pid_native == POSIX::getpid()
            && $loop->count == 0
            && $loop->stats->{run_once_calls} == 0);
    }
    ok($pid > 0, 'empty fork returns child pid in parent');
    is($loop->stats->{run_once_calls}, 1,
        'managed fork does not reset parent diagnostics');
    reap_ok($pid, 'empty fork');
}

{
    my $loop = Linux::Event::Loop->new;
    my $error;
    $loop->defer(sub {
        eval { $loop->fork };
        $error = $@;
        $loop->stop;
    });
    $loop->run;
    like($error, qr/Loop must be quiescent/, 'fork is rejected inside deferred dispatch');
}

{
    my $loop = Linux::Event::Loop->new;
    my $timer = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 60,
        on_timer => sub { },
    );
    my $pid = CORE::fork();
    die "CORE::fork failed: $!" if !defined $pid;
    if ($pid == 0) {
        my $driver_ok = !eval { $loop->run_once(0); 1 }
            && $@ =~ /cannot be used .* after fork/;
        my $introspection_ok = !eval { $loop->resources; 1 }
            && $@ =~ /cannot be used .* after fork/;
        my $timer_ok = !eval { $timer->cancel; 1 }
            && $@ =~ /cannot be used .* after fork/;
        child_exit($driver_ok && $introspection_ok && $timer_ok);
    }
    reap_ok($pid, 'inherited loop ownership guard');
    $timer->cancel;
}

{
    my $loop = Linux::Event::Loop->new;
    my $timer = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 60,
        on_timer => sub { },
    );
    my $before = $timer->deadline;
    my $pid = $loop->fork(clone => [$timer]);
    if ($pid == 0) {
        my $same_deadline = abs($timer->deadline - $before) < 0.01;
        child_exit($timer->is_active && $loop->has($timer) && $same_deadline);
    }
    ok($timer->is_active, 'cloned Timer remains active in parent');
    reap_ok($pid, 'Timer clone');
    $timer->cancel;
}

{
    my $loop = Linux::Event::Loop->new;
    my $timer = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 60,
        on_timer => sub { },
    );
    my $pid = $loop->fork;
    if ($pid == 0) {
        child_exit($timer->is_terminal && !$loop->has($timer));
    }
    ok($timer->is_active && $loop->has($timer),
        'unlisted Timer remains parent-owned');
    reap_ok($pid, 'default Timer child drop');
    $timer->cancel;
}

SKIP: {
    open my $ptmx, '+<', '/dev/ptmx'
        or skip '/dev/ptmx is unavailable for borrowed TTY fork validation', 6;
    skip '/dev/ptmx is not reported as a TTY on this system', 6 if !-t $ptmx;

    my $status_before = fcntl($ptmx, F_GETFL, 0);
    my $loop = Linux::Event::Loop->new;
    my $tty = Linux::Event::IO::TTY->new(
        loop => $loop,
        fh   => $ptmx,
        on_data => sub ($tty, $bytes) { },
    );
    my $pid = $loop->fork;
    if ($pid == 0) {
        child_exit(
            $tty->is_terminal
            && !$loop->has($tty)
            && defined(fileno($ptmx))
            && (fcntl($ptmx, F_GETFL, 0) & O_NONBLOCK)
        );
    }

    ok(!$tty->is_terminal && $loop->has($tty),
        'unlisted borrowed TTY remains active in parent');
    ok(fcntl($ptmx, F_GETFL, 0) & O_NONBLOCK,
        'child drop does not restore shared TTY flags out from under parent');
    reap_ok($pid, 'default borrowed TTY child drop');

    $tty->close;
    ok(defined fileno($ptmx),
        'parent borrowed TTY close leaves terminal handle open after fork');
    is(fcntl($ptmx, F_GETFL, 0), $status_before,
        'parent borrowed TTY close restores terminal flags after fork');
    close $ptmx;
}

{
    my $loop = Linux::Event::Loop->new;
    my $timer = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 60,
        on_timer => sub { },
    );
    my $pid = $loop->fork(move => [$timer]);
    if ($pid == 0) {
        child_exit($timer->is_active && $loop->has($timer));
    }
    ok($timer->is_terminal, 'moved Timer is terminal in parent');
    reap_ok($pid, 'Timer move');
}

{
    my $loop = Linux::Event::Loop->new;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => { on_data => sub { } },
    );
    my $pid = $loop->fork(share => [$listener]);
    if ($pid == 0) {
        child_exit($listener->is_running && $loop->has($listener)
            && defined($listener->fd));
    }
    ok($listener->is_running, 'shared Listener remains active in parent');
    reap_ok($pid, 'Listener share');
    $listener->close;
}

{
    my $loop = Linux::Event::Loop->new;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => { on_data => sub { } },
    );
    my $pid = $loop->fork(move => [$listener]);
    if ($pid == 0) {
        child_exit($listener->is_running && $loop->has($listener)
            && defined($listener->fd));
    }
    is($listener->state, 'moved', 'moved Listener is poisoned in parent');
    ok(!defined($listener->fd), 'moved Listener parent fd is closed');
    reap_ok($pid, 'Listener move');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $path = "$dir/watched";
    open my $out, '>', $path or die "open $path: $!";
    close $out;

    my $loop = Linux::Event::Loop->new;
    my $inotify = Linux::Event::Kernel::Inotify->new(loop => $loop);
    my $watch = $inotify->watch($path, on_modify => sub { });

    my $pid = $loop->fork(clone => [$inotify]);
    if ($pid == 0) {
        child_exit($inotify->is_active && $watch->is_active
            && $loop->has($inotify) && defined($inotify->fd));
    }
    ok($inotify->is_active && $watch->is_active,
        'cloned Inotify remains active in parent');
    reap_ok($pid, 'Inotify clone');
    $inotify->close;
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $path = "$dir/watched";
    open my $out, '>', $path or die "open $path: $!";
    close $out;

    my $loop = Linux::Event::Loop->new;
    my $inotify = Linux::Event::Kernel::Inotify->new(loop => $loop);
    my $watch = $inotify->watch($path, on_modify => sub { });

    my $pid = $loop->fork(move => [$inotify]);
    if ($pid == 0) {
        child_exit($inotify->is_active && $watch->is_active
            && $loop->has($inotify) && defined($inotify->fd));
    }
    is($inotify->state, 'moved', 'moved Inotify is poisoned in parent');
    ok($inotify->is_terminal, 'moved Inotify is terminal in parent');
    reap_ok($pid, 'Inotify move');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $path = "$dir/reconstruction-failure";
    open my $out, '>', $path or die "open $path: $!";
    close $out;

    my $loop = Linux::Event::Loop->new;
    my $timer = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 60,
        on_timer => sub { },
    );
    my $inotify = Linux::Event::Kernel::Inotify->new(loop => $loop);
    my $watch = $inotify->watch($path, on_modify => sub { });
    unlink $path or die "unlink $path: $!";

    my $ok = eval {
        $loop->fork(
            move  => [$timer],
            clone => [$inotify],
        );
        1;
    };
    my $error = $@;
    ok(!$ok, 'child reconstruction failure is reported to parent');
    like($error, qr/fork\(\): .*inotify_add_watch|fork\(\): .*No such file/i,
        'child reconstruction error is propagated');
    ok($timer->is_active && $loop->has($timer),
        'failed child reconstruction does not commit parent Timer move');
    ok($inotify->is_active && $loop->has($inotify),
        'failed child reconstruction leaves parent Inotify owned');
    $timer->cancel;
    $inotify->close;
}

{
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $stream = Linux::Event::IO::Sock::Stream->new(
        loop => $loop,
        fh => $left,
        on_data => sub { },
    );

    my $pid = $loop->fork(move => [$stream]);
    if ($pid == 0) {
        child_exit($stream->state eq 'active' && $loop->has($stream)
            && defined($stream->fd));
    }
    is($stream->state, 'moved', 'moved Stream is poisoned in parent');
    reap_ok($pid, 'Stream move');
    close $right;
}

{
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $stream = Linux::Event::IO::Sock::Stream->new(
        loop => $loop,
        fh => $left,
        on_data => sub { },
    );
    eval { $loop->fork(share => [$stream]) };
    like($@, qr/does not support 'share'/, 'Stream share is rejected before fork');
    $stream->close;
    close $right;
}

{
    my $loop = Linux::Event::Loop->new;
    eval { $loop->fork(share => 'all') };
    like($@, qr/share must be an array reference/, 'fork arguments are strict');
    eval { $loop->fork(unknown => []) };
    like($@, qr/unknown options/, 'unknown fork option is rejected');

    my $timer = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 60,
        on_timer => sub { },
    );
    eval { $loop->fork(clone => [$timer], move => [$timer]) };
    like($@, qr/only one disposition list/,
        'same resource cannot appear in multiple disposition lists');
    $timer->cancel;
}

done_testing;
