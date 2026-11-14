use v5.44;
use Test2::V1;
use IO::Async::Loop::Poll;
use IO::Async::Loop::Ppoll;
use IO::Poll;
use IO::Ppoll;
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGCHLD SIGUSR2);
use LibTmux::Async::Transport;

my $opaque_loop = bless [], 'IO::Async::Loop::Ppoll';
my $layout_error;
try { LibTmux::Async::Transport->new(loop => $opaque_loop) }
catch ($error) { $layout_error = $error }
bless $opaque_loop, 'UnexpectedLoopLayout';
T2->ok(
    defined($layout_error) && $layout_error isa LibTmux::X::Unsupported,
    'unexpected upstream object layout has a typed refusal'
);

for my $loop (
    IO::Async::Loop::Poll->new,
    IO::Async::Loop::Ppoll->new(poll => IO::Poll->new),
    do {
        my $poll = IO::Ppoll->new;
        $poll->sigmask_add(SIGCHLD);
        IO::Async::Loop::Ppoll->new(poll => $poll);
    },
    )
{
    my $error;
    try { LibTmux::Async::Transport->new(loop => $loop) }
    catch ($caught) { $error = $caught }
    T2->ok(
        defined($error) && $error isa LibTmux::X::Unsupported,
        'unsafe wait backend or blocked wait signal is refused before dispatch'
    );
}

my $loop      = IO::Async::Loop::Ppoll->new;
my $transport = LibTmux::Async::Transport->new(loop => $loop);
my $first     = $transport->execute(argv => [$^X, '-e', 'exit 0']);
$loop->await($first);
T2->ok($first->get->success, 'first job establishes loop-owned child watching');

my $original = POSIX::SigSet->new;
POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR2), $original)
    or die "block test signal: $!";
my $mask = POSIX::SigSet->new;
POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $mask) or die $!;
my @before = map { $mask->ismember($_) } 1 .. 64;
my $child  = $transport->execute(
    argv => [
        $^X, '-e', q{
        use POSIX qw(SIG_BLOCK SIGCHLD SIGUSR2);
        my $mask=POSIX::SigSet->new;
        POSIX::sigprocmask(SIG_BLOCK,POSIX::SigSet->new,$mask) or die $!;
        print $mask->ismember(SIGCHLD), ' ', $mask->ismember(SIGUSR2);
    }
    ],
);
$loop->await($child);
T2->is($child->get->stdout, '0 1',
    'async program unblocks CHLD and retains unrelated blocked signals');
my $close = $transport->close;
$loop->await($close);
T2->ok($close->is_done, 'close still proves child cleanup');
POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $mask) or die $!;
T2->is([map { $mask->ismember($_) } 1 .. 64],
    \@before, 'launch and close leave the caller mask owned by its loop');
POSIX::sigprocmask(SIG_SETMASK, $original) or die $!;

{
    no warnings 'redefine';
    local *LibTmux::Async::Transport::_prepare_child = sub {
        LibTmux::X::Transport->throw(
            message    => 'injected child preparation failure',
            dispatched => false
        );
    };
    my $transport = LibTmux::Async::Transport->new(loop => $loop);
    my $failed =
        $transport->execute(argv => [$^X, '-e', 'print "not dispatched"']);
    $loop->await($failed);
    my $error = scalar $failed->failure;
    T2->ok(
        $error isa LibTmux::X::Transport && !$error->dispatched,
        'child preparation failure remains typed and precedes dispatch'
    );
    T2->like(
        $error->message,
        qr/injected child preparation failure/,
        'preparation diagnostics survive the supervisor boundary'
    );
    my $close = $transport->close;
    $loop->await($close);
    T2->ok($close->is_done,
        'failed preparation still proves supervisor cleanup');
}

my $poll         = IO::Ppoll->new;
my $changed_loop = IO::Async::Loop::Ppoll->new(poll => $poll);
my $changed      = LibTmux::Async::Transport->new(loop => $changed_loop);
$poll->sigmask_add(SIGCHLD);
my $rejected = $changed->execute(argv => [$^X, '-e', 'exit 0']);
T2->ok(
    $rejected->is_failed
        && scalar($rejected->failure) isa LibTmux::X::Unsupported,
    'changed wait mask is refused at admission without a child'
);
T2->ok($changed->close->is_done,
    'refused admission leaves no cleanup obligation');
T2->done_testing;
