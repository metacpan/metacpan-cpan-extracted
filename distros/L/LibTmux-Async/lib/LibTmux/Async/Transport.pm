package LibTmux::Async::Transport;
use v5.44;
use Future;
use IO::Async::Loop::Ppoll 0.10;
use IO::Ppoll 0.14 ();
use IO::Async::Stream;
use POSIX qw(SIG_UNBLOCK SIGCHLD);
use LibTmux::ProcessJob;
use LibTmux::Async::X;

sub _validate_loop ($loop) {

    # Ppoll 0.10 stores the configured wait object here; its public constructor
    # also accepts plain IO::Poll, which cannot deliver CHLD atomically.
    LibTmux::X::Unsupported->throw(
        message =>
'use IO::Async::Loop::Ppoll with IO::Ppoll and a wait mask permitting SIGCHLD',
        dispatched => false,
        )
        unless ref($loop) eq 'IO::Async::Loop::Ppoll'
        && reftype($loop) eq 'HASH'
        && ref($loop->{poll}) eq 'IO::Ppoll'
        && reftype($loop->{poll}) eq 'HASH'
        && !$loop->{poll}->sigmask_ismember(SIGCHLD);
}

sub _prepare_child () {
    POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGCHLD))
        or LibTmux::X::Transport->throw(
        message    => "unblock async child SIGCHLD: $!",
        dispatched => false
        );
}

sub new ($class, %args) {
    LibTmux::X::InvalidArgument->throw(
        message => 'an explicit IO::Async::Loop is required')
        unless ref($args{loop}) && $args{loop}->isa('IO::Async::Loop');
    _validate_loop($args{loop});
    $args{max_concurrent} //= 4;
    $args{max_queue}      //= 64;
    LibTmux::X::InvalidArgument->throw(message =>
            'max_concurrent must be positive and max_queue nonnegative integers'
        )
        unless "$args{max_concurrent}" =~ /\A[1-9][0-9]*\z/
        && "$args{max_queue}" =~ /\A[0-9]+\z/;
    return bless {
        loop           => $args{loop},
        max_concurrent => $args{max_concurrent},
        max_queue      => $args{max_queue},
        jobs           => {},
        queue          => [],
        next_id        => 0,
        closing        => false,
        cleanup        => $args{loop}->new_future,
        cleanup_errors => []
    }, $class;
}

sub execute ($self, %request) {
    my $future = $self->{loop}->new_future;
    if ($self->{closing}) {
        return $future->fail(
            LibTmux::Async::X::Closed->new(message => 'transport is closing'));
    }
    my $copy;
    try {
        _validate_loop($self->{loop});
        LibTmux::X::InvalidArgument->throw(
            message => 'argv must be a nonempty array')
            unless ref($request{argv}) eq 'ARRAY' && $request{argv}->@*;
        $copy = {%request, argv => [$request{argv}->@*]};
        $copy->{env} = {%{$request{env}}} if exists $request{env};
    }
    catch ($error) { return $future->fail($error) }
    my $entry = {id => ++$self->{next_id}, request => $copy, future => $future};
    $future->on_cancel(sub { $entry->{job}->cancel if $entry->{job} });
    $self->{queue} = [grep { !$_->{future}->is_ready } $self->{queue}->@*];
    if (!$self->{queue}->@*
        && keys($self->{jobs}->%*) < $self->{max_concurrent})
    {
        $self->_launch($entry);
    }
    else {
        $self->{queue} = [grep { !$_->{future}->is_ready } $self->{queue}->@*];
        if ($self->{queue}->@* >= $self->{max_queue}) {
            $future->fail(
                LibTmux::Async::X::QueueFull->new(
                    message    => 'async request queue is full',
                    dispatched => false
                )
            );
        }
        else { push $self->{queue}->@*, $entry }
    }
    return $future;
}

sub _launch ($self, $entry) {
    return if $entry->{future}->is_ready;
    $self->{jobs}{$entry->{id}} = $entry;
    try {
        _validate_loop($self->{loop});
        my $job = LibTmux::ProcessJob->start(
            $entry->{request}->%*,
            spawner => sub ($code) {
                $self->{loop}->fork(
                    code    => sub { $code->(\&_prepare_child) },
                    on_exit => sub ($pid, $status) {
                        $entry->{exit_seen}   = true;
                        $entry->{exit_status} = $status;
                        $self->_maybe_finish($entry);
                    }
                );
            }
        );
        $entry->{job}    = $job;
        $entry->{reader} = $job->take_result_handle;
        my $stream = IO::Async::Stream->new(
            read_handle => $entry->{reader},
            on_read     => sub ($stream, $buffer, $eof) {
                unless ($entry->{error}) {
                    try { $job->consume($$buffer) }
                    catch ($error) { $entry->{error} = $error; $job->cancel }
                }
                $$buffer = '';
                if ($eof) { $entry->{eof} = true; $self->_maybe_finish($entry) }
                return 0;
            },
            on_read_error => sub ($stream, $errno) {
                $entry->{error} = LibTmux::X::Transport->new(
                    message    => "read async result: $errno",
                    dispatched => true
                );
                $job->cancel;
                $stream->close_now;
                $self->{loop}->remove($stream) if $stream->loop;
                $entry->{eof} = true;
                $self->_maybe_finish($entry);
            },
        );
        $entry->{stream} = $stream;
        delete $entry->{reader};
        $self->{loop}->add($stream);
    }
    catch ($error) {
        if ($entry->{job}) {
            $entry->{error} = $error;
            $entry->{job}->cancel;
            if (my $stream = $entry->{stream}) {
                $stream->close_now;
                $self->{loop}->remove($stream) if $stream->loop;
            }
            else {
                my $handle = delete $entry->{reader};
                close $handle if $handle;
            }
            $entry->{eof} = true;
            $self->_maybe_finish($entry);
        }
        else {
            delete $self->{jobs}{$entry->{id}};
            $entry->{future}->fail($error) unless $entry->{future}->is_ready;
            $self->_drain;
            $self->_check_close;
        }
    }
}

sub _maybe_finish ($self, $entry) {
    return if $entry->{terminal} || !$entry->{eof} || !$entry->{exit_seen};
    $entry->{terminal} = true;
    my ($result, $error) = (undef, $entry->{error});
    try { $result = $entry->{job}->finish }
    catch ($caught) { $error //= $caught }
    if (!$entry->{job}->cleanup_complete) {
        push $self->{cleanup_errors}->@*,
            $error // LibTmux::X::Transport->new(
            message    => 'supervisor exit did not prove program cleanup',
            dispatched => true
            );
    }
    if (my $stream = delete $entry->{stream}) {
        $stream->close_now;
        $self->{loop}->remove($stream) if $stream->loop;
    }
    delete $self->{jobs}{$entry->{id}};
    unless ($entry->{future}->is_ready) {
        if   ($error) { $entry->{future}->fail($error) }
        else          { $entry->{future}->done($result) }
    }
    delete $entry->{job};
    $self->_drain;
    $self->_check_close;
}

sub _drain ($self) {
    return if $self->{closing};
    while ($self->{queue}->@*
        && keys($self->{jobs}->%*) < $self->{max_concurrent})
    {
        my $entry = shift $self->{queue}->@*;
        $self->_launch($entry) unless $entry->{future}->is_ready;
    }
}

sub _check_close ($self) {
    return
           unless $self->{closing}
        && !keys($self->{jobs}->%*)
        && !$self->{cleanup}->is_ready;
    if ($self->{cleanup_errors}->@*) {
        $self->{cleanup}->fail($self->{cleanup_errors}[0]);
    }
    else { $self->{cleanup}->done(undef) }
}

sub close ($self) {
    unless ($self->{closing}) {
        $self->{closing} = true;
        my @queued = splice $self->{queue}->@*;
        $_->{future}->cancel for @queued;
        $_->{future}->cancel for values $self->{jobs}->%*;
    }
    $self->_check_close;
    my $observer = $self->{loop}->new_future;
    $self->{cleanup}->on_ready(
        sub ($private) {
            return if $observer->is_ready;
            if ($private->is_done) { $observer->done(undef) }
            else                   { $observer->fail(scalar $private->failure) }
        }
    );
    return $observer;
}

=head1 NAME

LibTmux::Async::Transport - Bounded asynchronous process execution

=head1 METHODS

=head2 new

C<new(loop =E<gt> $loop, max_concurrent =E<gt> 4, max_queue =E<gt> 64)>
borrows an L<IO::Async::Loop::Ppoll> backed by L<IO::Ppoll>. Construct that
class explicitly; automatic loop selection can choose an unsupported backend.
Other classes, a substituted poll implementation, or a wait mask blocking
SIGCHLD throw L<Unsupported|LibTmux::X/Unsupported> before dispatch. The loop
owns supervisor reaping; competing external all-child reapers are unsupported.
The library never runs, stops, or replaces it.

Ppoll blocks watched signals outside its atomic wait. Its shared SIGCHLD watch
can outlive this transport. C<close> leaves the caller-selected loop and its
signal policy intact. Do not change the backend or its wait mask while jobs
or cleanup remain active. Async children unblock only SIGCHLD before process
supervision; other mask bits remain unchanged in the child. This lets a new
tmux daemon observe pane exits without changing synchronous core's mask policy.

=head2 execute

Accepts the same literal process arguments as L<LibTmux::Transport/run>.
Returns a L<Future> yielding one L<command result|LibTmux::Transport/RESULTS>.
Typed core exceptions remain the failure value. Queue overflow fails with
L<QueueFull|LibTmux::Async::X/QueueFull> before dispatch.
The backend is checked again at admission and launch. Child preparation
failures retain a typed diagnostic and C<dispatched> false, with supervisor
exit still required before cleanup completes.

The shared L<LibTmux::ProcessJob> owns supervision. Cancelling the Future
requests cleanup; it does not prove exit or reverse command effects.

=head2 close

Begin idempotent shutdown and return a fresh observer Future. New admissions
fail with L<Closed|LibTmux::Async::X/Closed>; queued requests are cancelled
without dispatch and running jobs are cancelled. Cancelling an observer never
cancels private cleanup. Only successful C<is_done> completion proves all owned
jobs, pipes, and watchers have completed cleanup. The borrowed loop remains
usable. Callers must keep driving it through shutdown.

=cut
