use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IO::Select;
use POSIX qw(SIGUSR1);

use Linux::Event::Loop;
use Linux::Event::Kernel::Event;
use Linux::Event::Kernel::Inotify;
use Linux::Event::Kernel::Process;
use Linux::Event::Kernel::Signal;
use Linux::Event::Kernel::Timer;

sub exception ($code) {
    local $@;
    return eval { $code->(); 1 } ? '' : "$@";
}

sub foreign_selector ($loop) {
    my $fd = $loop->poll_fd;
    cmp_ok($fd, '>=', 0, 'poll_fd returns the owned epoll descriptor');

    open my $fh, '<&', $fd
        or die "dup poll_fd $fd failed: $!";
    return ($fh, IO::Select->new($fh));
}

sub await_foreign_readable ($selector, $label, $timeout = 3) {
    my @ready = $selector->can_read($timeout);
    ok(@ready, $label);
    return scalar @ready;
}

{
    my $loop = Linux::Event::Loop->new;
    my $fd = $loop->poll_fd;
    is($loop->poll_fd, $fd, 'poll_fd is stable for the life of the Loop');
    is($loop->poll, 0, 'poll is nonblocking when no event is ready');
    is($loop->poll, 0, 'a prior empty poll does not change readiness state');

    my $stats = $loop->stats;
    is($stats->{poll_calls}, 2, 'poll calls have their own diagnostic counter');
    is($stats->{run_once_calls}, 0, 'poll does not masquerade as run_once');

    $loop->stop;
    is($loop->poll, 0, 'a stale stop request does not suppress poll');

    $loop->reset_stats;
    is($loop->stats->{poll_calls}, 0, 'reset_stats clears poll_calls');
}

{
    my $loop = Linux::Event::Loop->new;
    my ($poll_fh, $selector) = foreign_selector($loop);
    pipe(my $read_fh, my $write_fh) or die "pipe failed: $!";

    my $seen = '';
    my $running;
    my $reentrant_error;
    my $registration = $loop->watch(
        fh => $read_fh,
        read => sub ($watcher) {
            $running = $loop->running;
            $reentrant_error = exception(sub { $loop->poll });
            my $n = sysread($watcher->fh, my $bytes, 16);
            die "sysread failed: $!" if !defined $n;
            $seen .= $bytes;
        },
    );

    is(syswrite($write_fh, 'io'), 2, 'wrote raw I/O test payload');
    await_foreign_readable($selector,
        'foreign selector observes Linux::Event I/O readiness');
    cmp_ok($loop->poll, '>=', 1, 'poll dispatches raw I/O readiness');
    is($seen, 'io', 'I/O callback ran through the foreign-loop boundary');
    ok($running, 'running is true while poll dispatches a callback');
    like($reentrant_error, qr/already running|recursive|driver/i,
        'poll rejects recursive drive of the same Loop');

    $registration->cancel;
    close $read_fh;
    close $write_fh;
    close $poll_fh;
}

{
    my $loop = Linux::Event::Loop->new;
    my ($poll_fh, $selector) = foreign_selector($loop);
    my $seen = 0;

    my $timer = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 0.01,
        on_timer => sub { $seen++ },
    );

    await_foreign_readable($selector,
        'future Timer readiness makes poll_fd readable');
    cmp_ok($loop->poll, '>=', 1, 'poll dispatches Timer readiness');
    is($seen, 1, 'Timer callback ran through the foreign-loop boundary');

    $timer->cancel if $timer->is_active;
    close $poll_fh;
}

{
    my $loop = Linux::Event::Loop->new;
    my ($poll_fh, $selector) = foreign_selector($loop);
    my $count = 0;

    my $event = Linux::Event::Kernel::Event->new(
        loop => $loop,
        on_event => sub ($self, $value) { $count += $value },
    );
    $event->signal(3);

    await_foreign_readable($selector,
        'eventfd notification makes poll_fd readable');
    cmp_ok($loop->poll, '>=', 1, 'poll dispatches eventfd readiness');
    is($count, 3, 'eventfd callback ran through the foreign-loop boundary');

    $event->cancel;
    close $poll_fh;
}

{
    my $loop = Linux::Event::Loop->new;
    my ($poll_fh, $selector) = foreign_selector($loop);
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'foreign-inotify.txt');
    open my $seed, '>', $path or die "open $path: $!";
    close $seed;

    my $seen = 0;
    my $inotify = Linux::Event::Kernel::Inotify->new(loop => $loop);
    my $watch = $inotify->watch(
        $path,
        on_modify => sub ($event) { $seen++ },
    );

    open my $out, '>>', $path or die "open $path: $!";
    print {$out} "changed\n";
    close $out;

    await_foreign_readable($selector,
        'inotify readiness makes poll_fd readable');
    cmp_ok($loop->poll, '>=', 1, 'poll dispatches inotify readiness');
    is($seen, 1, 'inotify callback ran through the foreign-loop boundary');

    $watch->cancel;
    $inotify->close;
    close $poll_fh;
}

{
    my $loop = Linux::Event::Loop->new;
    my ($poll_fh, $selector) = foreign_selector($loop);
    my $seen = 0;

    my $pending = $loop->defer(sub { $seen++ });
    await_foreign_readable($selector,
        'deferred work makes poll_fd readable');
    cmp_ok($loop->poll, '>=', 1, 'poll dispatches deferred work');
    is($seen, 1, 'deferred callback ran through the foreign-loop boundary');
    ok(!$pending->is_active, 'foreign-driven deferred handle completes');

    close $poll_fh;
}

{
    my $loop = Linux::Event::Loop->new;
    my ($poll_fh, $selector) = foreign_selector($loop);
    my $seen = 0;

    my $signal = Linux::Event::Kernel::Signal->new(
        loop => $loop,
        signals => SIGUSR1,
        on_signal => sub { $seen++ },
    );

    kill SIGUSR1, $$ or die "kill SIGUSR1 failed: $!";

    await_foreign_readable($selector,
        'signalfd readiness makes poll_fd readable');
    cmp_ok($loop->poll, '>=', 1, 'poll dispatches signal readiness');
    is($seen, 1, 'signal callback ran through the foreign-loop boundary');

    $signal->cancel;
    close $poll_fh;
}

{
    my $loop = Linux::Event::Loop->new;
    my ($poll_fh, $selector) = foreign_selector($loop);
    my $seen = 0;

    my $process = Linux::Event::Kernel::Process->spawn(
        command => [$^X, '-e', 'exit 0'],
        on_exit => sub { $seen++ },
    );
    $loop->add($process);

    await_foreign_readable($selector,
        'pidfd readiness makes poll_fd readable', 5);
    cmp_ok($loop->poll, '>=', 1, 'poll dispatches process readiness');
    is($seen, 1, 'process callback ran through the foreign-loop boundary');

    close $poll_fh;
}

done_testing;
