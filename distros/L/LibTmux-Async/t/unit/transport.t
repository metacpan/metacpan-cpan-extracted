use v5.44;
use Test2::V1;
use File::Temp qw(tempdir);
use POSIX      qw(mkfifo);
use IO::Async::Loop::Ppoll;
use Future;

my $loaded = eval { require LibTmux::Async::Transport; 1 };
T2->ok($loaded, 'separate optional async transport loads');
unless ($loaded) { T2->diag($@); T2->done_testing; exit }
my $loop      = IO::Async::Loop::Ppoll->new;
my $transport = LibTmux::Async::Transport->new(
    loop           => $loop,
    max_concurrent => 2,
    max_queue      => 2
);
my $root = tempdir('libtmux-perl-async-XXXX', TMPDIR => 1, CLEANUP => 1);
my $fifo = "$root/fifo";
mkfifo($fifo, 0600) or die $!;
my $reader = $transport->execute(
    argv => [
        $^X, '-e', 'open my $f,"<",$ARGV[0] or die $!; print scalar <$f>',
        $fifo
    ],
    timeout => 0.8
);
my $writer = $transport->execute(
    argv => [
        $^X, '-e', 'open my $f,">",$ARGV[0] or die $!; print {$f} "ready\\n"',
        $fifo
    ],
    timeout => 0.8
);
T2->ok($reader isa Future, 'request returns standard Future');
my $both = Future->needs_all($reader, $writer);
$loop->await($both);
T2->is($reader->get->stdout, "ready\n",
    'concurrent subprocesses progress without a blocking facade callback');
T2->is($writer->get->exit_code, 0, 'concurrent writer completed');
my $close = $transport->close;
$loop->await($close);
T2->ok($close->is_done, 'successful close proves cleanup');

$transport = LibTmux::Async::Transport->new(
    loop           => $loop,
    max_concurrent => 1,
    max_queue      => 0
);
my $pending =
    $transport->execute(argv => [$^X, '-e', 'sleep 20'], timeout => 0.8);
my $overflow = $transport->execute(argv => [$^X, '-e', 'exit 0']);
T2->ok($overflow->is_failed, 'bounded admission rejects overflow');
T2->ok($overflow->failure isa LibTmux::Async::X::QueueFull,
    'typed queue failure');
$pending->cancel;
T2->ok($pending->is_cancelled, 'request cancellation is immediately visible');
my $observer = $transport->close;
$observer->cancel;
my $observer2 = $transport->close;
$loop->await($observer2);
T2->ok($observer2->is_done, 'cancelled close observer cannot abandon cleanup');
my $closed = $transport->execute(argv => [$^X, '-e', 'exit 0']);
T2->ok($closed->is_failed && $closed->failure isa LibTmux::Async::X::Closed,
    'closed transport rejects new work');
my $later = $loop->later;
$loop->await($later);
T2->ok($later->is_done, 'borrowed loop remains usable after transport close');

$transport = LibTmux::Async::Transport->new(loop => $loop);
my $failed = $transport->execute(argv => ['/missing-libtmux-async-executable']);
$loop->await($failed);
T2->ok($failed->is_failed && $failed->failure isa LibTmux::X::Spawn,
    'typed core failure passes through Future');
my $done = $transport->close;
$loop->await($done);
T2->ok($done->is_done, 'failed exec still has completed cleanup');
$transport = LibTmux::Async::Transport->new(
    loop           => $loop,
    max_concurrent => 1,
    max_queue      => 2
);
my (@order, $third);
my $first  = $transport->execute(argv => [$^X, '-e', 'print "first"']);
my $second = $transport->execute(argv => [$^X, '-e', 'print "second"']);
$first->on_done(
    sub ($result) {
        push @order, $result->stdout;
        $third = $transport->execute(argv => [$^X, '-e', 'print "third"']);
        $third->on_done(sub($value) { push @order, $value->stdout });
    }
);
$second->on_done(sub($value) { push @order, $value->stdout });
$loop->await($second);
$loop->await($third);
T2->is(\@order, [qw(first second third)],
    'completion callbacks cannot overtake older queued requests');
$loop->await($transport->close);
T2->done_testing;
