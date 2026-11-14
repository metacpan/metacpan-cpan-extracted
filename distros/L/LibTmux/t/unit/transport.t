use v5.44;
use Test2::V1;
use Scalar::Util qw(blessed);
use POSIX        qw(WNOHANG SIGCHLD SIGINT SIGTERM SIG_BLOCK SIG_SETMASK);
use JSON::PP     ();

my $loaded = eval { require LibTmux::Transport; 1 };
T2->ok($loaded, 'bounded literal process transport is loadable');
unless ($loaded) { T2->diag($@); T2->done_testing; exit }
T2->ok(LibTmux::Transport->can('start'), 'nonblocking ProcessJob seam exists');
if (LibTmux::Transport->can('start')) {
    my $job =
        LibTmux::Transport->start(argv => [$^X, '-e', 'print "job-result"']);
    T2->is($job->wait->stdout, 'job-result',
        'sync waiter consumes the shared job protocol');
}

sub run (@argv) { LibTmux::Transport->run(argv => \@argv, timeout => 0.8) }
my $marker = q{$(printf unsafe); ' " } . chr(92);
my $result =
    run($^X, '-e', 'print $ARGV[0]; print STDERR "err"; exit 7', $marker);
T2->is($result->stdout,    $marker, 'literal argv has no shell interpretation');
T2->is($result->stderr,    'err',   'stderr retained separately');
T2->is($result->exit_code, 7,       'ordinary nonzero exit is a result');
T2->is($result->signal,    0,       'ordinary exit is not a signal');

$result = LibTmux::Transport->run(
    argv => [
        $^X,
        '-e',
'$|=1; print "x"x131072; print STDERR "y"x131072; local $/; my $v=<STDIN>; print length($v)'
    ],
    stdin   => 'z' x 131072,
    timeout => 0.8,
);
T2->is(length($result->stderr),
    131072, 'concurrent stderr draining avoids pipe deadlock');
T2->is(substr($result->stdout, -6),
    '131072', 'stdin writing and stdout draining complete');

my $reaped = 0;
{
    local $SIG{CHLD} = sub {
        while (waitpid(-1, WNOHANG) > 0) { $reaped++ }
    };
    my $handler = $SIG{CHLD};
    $result = run($^X, '-e', 'print "retained"; exit 9');
    T2->is($result->exit_code, 9,
        'caller reaper cannot destroy the program result');
    T2->is($SIG{CHLD}, $handler, 'caller SIGCHLD disposition preserved');
}

{
    my $old     = POSIX::SigSet->new;
    my $blocked = POSIX::SigSet->new(SIGCHLD, SIGINT, SIGTERM);
    POSIX::sigprocmask(SIG_BLOCK, $blocked, $old);
    my ($observed, $failure);
    try {
        $observed = run(
            $^X, '-e', q{
            use POSIX ();
            my $mask = POSIX::SigSet->new;
            POSIX::sigprocmask(POSIX::SIG_BLOCK(), undef, $mask);
            print $mask->ismember($_)
                for POSIX::SIGCHLD(), POSIX::SIGINT(), POSIX::SIGTERM();
            close STDOUT;
            close STDERR;
            my $sum = 0;
            $sum += $_ for 1..100000;
        }
        );
    }
    catch ($error) { $failure = $error }
    my $after = POSIX::SigSet->new;
    POSIX::sigprocmask(SIG_BLOCK, undef, $after);
    POSIX::sigprocmask(SIG_SETMASK, $old);
    T2->is($failure, undef,
        'EOF before exit wakes the supervisor with caller CHLD blocked');
    T2->is($observed ? $observed->stdout : undef,
        '111', 'program retains the caller signal mask');
    T2->ok(
        $after->ismember(SIGCHLD)
            && $after->ismember(SIGINT)
            && $after->ismember(SIGTERM),
        'caller signal mask remains blocked'
    );
}

sub throws ($code, $type) {
    my $e;
    try { $code->() } catch ($caught) {
        $e = $caught
    }
    T2->ok(blessed($e) && $e->isa("LibTmux::X::$type"), $type);
    return $e;
}
throws(sub { run('/definitely-missing-libtmux-perl-program') }, 'Spawn');
throws(
    sub {
        LibTmux::Transport->run(
            argv    => [$^X, '-e', 'sleep 20'],
            timeout => 0.03
        );
    },
    'Timeout'
);
my $limited = throws(
    sub {
        LibTmux::Transport->run(
            argv       => [$^X, '-e', 'print "x"x100000'],
            max_output => 1024
        );
    },
    'OutputLimit'
);
T2->ok(
    $limited->result && length($limited->result->stdout) <= 1024,
    'output-limit failure preserves bounded partial process result'
);
pipe(my $cancel_r, my $cancel_w) or die $!;
syswrite($cancel_w, 'cancel');
throws(
    sub {
        LibTmux::Transport->run(
            argv      => [$^X, '-e', 'sleep 20'],
            cancel_fh => $cancel_r
        );
    },
    'Cancelled'
);
T2->ok(defined fileno($cancel_r), 'borrowed cancellation handle remains open');
close $cancel_r;
close $cancel_w;
throws(sub { run($^X, '-e', "a\0b") }, 'InvalidArgument');
$result = LibTmux::Transport->run(
    argv    => [$^X, '-e', 'close STDIN; print "done"'],
    stdin   => 'x' x 100000,
    timeout => 0.8
);
T2->is($result->stdout, 'done',
    'early stdin closure does not signal the caller');

my $corrupt = LibTmux::Transport->start(argv => [$^X, '-e', 'print "bytes"']);
my $wire_handle = $corrupt->take_result_handle;
my $wire        = do { local $/; <$wire_handle> };
close $wire_handle;
waitpid($corrupt->pid, 0);
my $record = JSON::PP->new->utf8->decode($wire);
$record->{stdout} = '***';
$corrupt->consume(JSON::PP->new->utf8->encode($record));
throws(sub { $corrupt->finish }, 'Transport');

T2->done_testing;
