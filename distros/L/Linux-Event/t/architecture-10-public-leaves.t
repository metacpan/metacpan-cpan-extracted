use v5.36;
use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);
use Socket qw(AF_UNIX SOCK_DGRAM SOCK_STREAM);

use Linux::Event::IO ();
use Linux::Event::IO::Pipe ();
use Linux::Event::IO::TTY ();
use Linux::Event::IO::Sock ();
use Linux::Event::IO::Sock::Stream ();
use Linux::Event::IO::Sock::Listener ();
use Linux::Event::IO::Sock::Dgram ();
use Linux::Event::Kernel ();
use Linux::Event::Kernel::Timer ();
use Linux::Event::Kernel::Signal ();
use Linux::Event::Kernel::Event ();
use Linux::Event::Kernel::Process ();

{
    package T::ArchitecturePipe;
    use parent 'Linux::Event::IO::Pipe';
    sub on_data ($self, $bytes) { }
}
{
    package T::ArchitectureTTY;
    use parent 'Linux::Event::IO::TTY';
    sub on_data ($self, $bytes) { }
}
{
    package T::ArchitectureSockStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($self, $bytes) { }
}
{
    package T::ArchitectureStatefulSockStream;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub new ($class, %option) {
        my $self = $class->SUPER::new(%option);
        $self->{application_sequence} = 17;
        return $self;
    }

    sub application_sequence ($self, @value) {
        $self->{application_sequence} = $value[0] if @value;
        return $self->{application_sequence};
    }

    sub on_data ($self, $bytes) { }
}
{
    package T::ArchitectureDgram;
    use parent 'Linux::Event::IO::Sock::Dgram';
    sub on_datagram ($self, $bytes, $peer) { }
}
{
    package T::ArchitectureEventMissing;
    use parent 'Linux::Event::Kernel::Event';
}
{
    package T::ArchitectureEvent;
    use parent 'Linux::Event::Kernel::Event';
    sub on_event ($self, $count) { }
}

ok(Linux::Event::IO::Pipe->isa('Linux::Event::_ByteStream'),
    'Pipe leaf uses the ordered-byte implementation');
ok(Linux::Event::IO::TTY->isa('Linux::Event::_ByteStream'),
    'TTY leaf uses the ordered-byte implementation');
ok(Linux::Event::IO::Sock::Stream->isa('Linux::Event::_Socket::Stream'),
    'Sock::Stream uses the connected stream-socket implementation');
ok(Linux::Event::IO::Sock::Listener->isa('Linux::Event::_Socket::Listener'),
    'Sock::Listener uses the listener implementation');
ok(Linux::Event::IO::Sock::Dgram->isa('Linux::Event::_Socket::Dgram'),
    'Sock::Dgram uses the datagram implementation');

pipe(my $pipe_read, my $pipe_write) or die "pipe: $!";
my $pipe = T::ArchitecturePipe->new(read_fh => $pipe_read);
ok($pipe->has_read && !$pipe->has_write, 'Pipe leaf preserves directional IO');
$pipe->close;
close $pipe_write;

my ($regular_fh) = tempfile();
my $pipe_error = eval { T::ArchitecturePipe->new(read_fh => $regular_fh); 1 }
    ? '' : "$@";
like($pipe_error, qr/not a pipe or FIFO/, 'Pipe leaf rejects a non-pipe handle');
close $regular_fh;

pipe(my $not_tty_read, my $not_tty_write) or die "pipe: $!";
my $tty_error = eval { T::ArchitectureTTY->new(read_fh => $not_tty_read); 1 }
    ? '' : "$@";
like($tty_error, qr/not a TTY or PTY/, 'TTY leaf rejects a non-terminal handle');
close $not_tty_read;
close $not_tty_write;

SKIP: {
    open my $ptmx, '+<', '/dev/ptmx'
        or skip '/dev/ptmx is unavailable for TTY validation', 2;
    skip '/dev/ptmx is not reported as a TTY on this system', 2 if !-t $ptmx;
    my $tty = T::ArchitectureTTY->new(fh => $ptmx);
    ok($tty->isa('Linux::Event::IO::TTY'), 'TTY leaf accepts a real pseudo-terminal handle');
    $tty->close;

    open my $closure_ptmx, '+<', '/dev/ptmx'
        or die "reopen /dev/ptmx: $!";
    my $closure_tty = Linux::Event::IO::TTY->new(
        fh => $closure_ptmx,
        on_data => sub ($object, $bytes) { },
    );
    ok($closure_tty->isa('Linux::Event::IO::TTY'),
        'public TTY leaf accepts a constructor callback');
    $closure_tty->close;
}

socketpair(my $stream_fh, my $stream_peer, AF_UNIX, SOCK_STREAM, 0)
    or die "stream socketpair: $!";
my $stream = T::ArchitectureSockStream->new(fh => $stream_fh);
ok($stream->isa('Linux::Event::IO::Sock::Stream'),
    'connected SOCK_STREAM constructs through the public leaf');
$stream->close;
close $stream_peer;

socketpair(my $stateful_fh, my $stateful_peer, AF_UNIX, SOCK_STREAM, 0)
    or die "stateful socketpair: $!";
my $stateful = T::ArchitectureStatefulSockStream->new(fh => $stateful_fh);
is($stateful->application_sequence, 17,
    'Sock::Stream subclass owns ordinary instance state');
$stateful->application_sequence(23);
is($stateful->application_sequence, 23,
    'Sock::Stream subclass accessor updates its own instance state');
$stateful->close;
is($stateful->application_sequence, 23,
    'Stream teardown preserves unrelated subclass-owned state');
close $stateful_peer;

socketpair(my $pipe_socket, my $pipe_socket_peer, AF_UNIX, SOCK_STREAM, 0)
    or die "stream socketpair: $!";
$pipe_error = eval { T::ArchitecturePipe->new(fh => $pipe_socket); 1 }
    ? '' : "$@";
like($pipe_error, qr/not a pipe or FIFO/,
    'Pipe leaf rejects a stream socket even though both carry ordered bytes');
close $pipe_socket;
close $pipe_socket_peer;

socketpair(my $dgram_fh, my $dgram_peer, AF_UNIX, SOCK_DGRAM, 0)
    or die "datagram socketpair: $!";
my $dgram = T::ArchitectureDgram->new(fh => $dgram_fh);
ok($dgram->isa('Linux::Event::IO::Sock::Dgram'),
    'SOCK_DGRAM constructs through the public leaf');
$dgram->close;
close $dgram_peer;

my $event_error = eval { T::ArchitectureEventMissing->new; 1 } ? '' : "$@";
like($event_error, qr/must define on_event/, 'Kernel::Event subclasses require on_event');
my $event = T::ArchitectureEvent->new;
ok($event->isa('Linux::Event::Kernel::Event'),
    'eventfd abstraction constructs through Kernel::Event');
$event->cancel;

for my $retired (qw(
    Linux::Event::Timer
    Linux::Event::Signal
    Linux::Event::Wakeup
    Linux::Event::Process
)) {
    ok(!$retired->can('new'), "$retired is not retained as a kernel implementation base");
}

done_testing;
