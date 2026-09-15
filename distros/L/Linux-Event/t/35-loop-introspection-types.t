use v5.36;
use strict;
use warnings;
use Test::More;
use POSIX qw(SIGUSR1);
use Scalar::Util qw(refaddr);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::IO::Pipe;
use Linux::Event::IO::Sock::Dgram;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Kernel::Event;
use Linux::Event::Kernel::Process;
use Linux::Event::Kernel::Signal;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

{
    package T::InspectPipe;
    use parent 'Linux::Event::IO::Pipe';
    sub on_data ($pipe, $bytes) { }
}

{
    package T::InspectStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { }
}

{
    package T::InspectDgram;
    use parent 'Linux::Event::IO::Sock::Dgram';
    sub on_datagram ($socket, $payload, $peer) { }
}

{
    package T::InspectTimer;
    use parent 'Linux::Event::Kernel::Timer';
    sub on_timer ($timer) { }
}

{
    package T::InspectSignal;
    use parent 'Linux::Event::Kernel::Signal';
    sub on_signal ($signal, $number, $count) { }
}

{
    package T::InspectEvent;
    use parent 'Linux::Event::Kernel::Event';
    sub on_event ($event, $count) { }
}

{
    package T::InspectProcess;
    use parent 'Linux::Event::Kernel::Process';
    sub on_exit ($process) { $process->loop->stop }
}

my $loop = Linux::Event::Loop->new;
socketpair(my $stream_fh, my $peer_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
pipe(my $pipe_read, my $pipe_write) or die "pipe: $!";

my %object;
$object{pipe} = T::InspectPipe->new(
    loop => $loop, read_fh => $pipe_read,
);
$object{stream} = T::InspectStream->new(
    loop => $loop, fh => $stream_fh,
);
$object{listener} = Linux::Event::IO::Sock::Listener->new(
    loop => $loop, stream => { class => 'T::InspectStream' },
    host => '127.0.0.1', port => 0,
);
$object{dgram} = T::InspectDgram->new(
    loop => $loop, host => '127.0.0.1', port => 0,
);
$object{timer} = T::InspectTimer->new(
    loop => $loop, after => 60,
);
$object{signal} = T::InspectSignal->new(
    loop => $loop, signals => [SIGUSR1],
);
$object{event} = T::InspectEvent->new(loop => $loop);
$object{process} = T::InspectProcess->spawn(
    loop => $loop, command => [$^X, '-e', 'exit 0'],
);

is_deeply(
    $loop->census,
    {
        pipe => 1, tty => 0, stream => 1, listener => 1, dgram => 1,
        timer => 1, signal => 1, event => 1, process => 1,
    },
    'census discovers public IO and Kernel types from authoritative state',
);
is($loop->count, 8, 'count excludes private backing objects and registrations');

my %seen = map { refaddr($_) => 1 } @{ $loop->objects };
for my $type (sort keys %object) {
    ok($seen{ refaddr($object{$type}) }, "objects contains exact $type object");
    my $snapshot = $loop->inspect($object{$type});
    is($snapshot->{type}, $type, "$type inspection has canonical type");
    is($snapshot->{registered}, 1, "$type inspection is registered");
    ok(defined $snapshot->{state}, "$type inspection has state");
}

ok(exists $loop->inspect($object{pipe})->{pending_bytes},
    'Pipe inspection includes ordered-byte queue state');
is($loop->inspect($object{pipe})->{read_fd}, $object{pipe}->read_fd,
    'Pipe inspection exposes the readable descriptor');
ok(!exists $loop->inspect($object{pipe})->{local},
    'Pipe inspection does not expose socket address fields');
ok(exists $loop->inspect($object{stream})->{pending_bytes},
    'stream-socket inspection includes ordered-byte queue state');
is($loop->inspect($object{stream})->{read_fd}, $object{stream}->read_fd,
    'stream-socket inspection exposes the readable descriptor');
is($loop->inspect($object{stream})->{write_fd}, $object{stream}->write_fd,
    'stream-socket inspection exposes the writable descriptor');
ok(exists $loop->inspect($object{stream})->{local},
    'stream-socket inspection includes socket address state');
ok(exists $loop->inspect($object{listener})->{accepted},
    'Listener inspection includes accept count');
ok(exists $loop->inspect($object{dgram})->{pending_datagrams},
    'Dgram inspection includes packet queue state');
is_deeply($loop->inspect($object{signal})->{signals}, [SIGUSR1],
    'Signal inspection includes subscribed numbers');
is($loop->inspect($object{process})->{pid}, $object{process}->pid,
    'Process inspection includes pid');

my %reason = map { $_->{type} => 1 } @{ $loop->why_alive };
ok($reason{$_}, "why_alive contains $_ reason")
    for sort keys %object;

$object{timer}->cancel;
$object{signal}->cancel;
$object{event}->cancel;
$object{listener}->close;
$object{dgram}->close;
$object{stream}->close;
$object{pipe}->close;
close $pipe_write;
close $peer_fh;

$loop->run;
is($loop->count, 0, 'completed and closed objects leave no liveness reasons');
is_deeply($loop->why_alive, [], 'why_alive is empty after cleanup');

done_testing;
