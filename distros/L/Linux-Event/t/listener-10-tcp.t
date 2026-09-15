use v5.36;
use strict;
use warnings;
use Test::More;
use Fcntl qw(F_GETFD F_GETFL FD_CLOEXEC O_NONBLOCK);
use Socket qw(AF_INET SOCK_STREAM inet_aton pack_sockaddr_in);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

our ($LOOP, $STATE);

{
    package T::AcceptedTCPListener;
    use parent 'Linux::Event::IO::Sock::Listener';

    sub on_accept ($listener, $stream) {
        my $state = $stream->data;
        $state->{accepted_stream} = $stream;
        $state->{accept_loop} = $stream->loop;
        push @{ $state->{order} }, 'accept';
        return;
    }
}

{
    package T::AcceptedTCPStream;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub on_ready ($stream) {
        my $state = $stream->data;
        push @{ $state->{order} }, 'ready';
        $state->{stream} = $stream;
        $state->{peer} = $stream->peer;
        $state->{status_flags} = fcntl($stream->fh, Fcntl::F_GETFL(), 0);
        $state->{fd_flags} = fcntl($stream->fh, Fcntl::F_GETFD(), 0);
        $state->{written} = $stream->write('ok');
        $main::LOOP->stop;
    }

    sub on_data ($stream, $bytes) { }

    sub on_error ($stream, $error) {
        $stream->data->{error} = $error;
        $main::LOOP->stop;
    }
}

$LOOP = Linux::Event::Loop->new;
$STATE = { order => [] };
my $listener = T::AcceptedTCPListener->new(
    loop => $LOOP, host => '127.0.0.1', port => 0,
    stream => { class => 'T::AcceptedTCPStream', data => $STATE },
);

is($listener->state, 'listening', 'loop constructor option attaches Listener');
is($listener->loop, $LOOP, 'Listener exposes its Loop');
is($listener->host, '127.0.0.1', 'Listener reports bound host');
ok($listener->port > 0, 'port zero reports kernel-assigned port');
is($listener->family, 'inet', 'Listener reports symbolic IPv4 family');
is($listener->family_number, AF_INET,
    'Listener reports native IPv4 family separately');
ok($listener->is_tcp, 'TCP Listener identifies as TCP');
ok(!$listener->is_unix, 'TCP Listener does not identify as Unix');

socket(my $client, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
connect($client, pack_sockaddr_in($listener->port, inet_aton('127.0.0.1')))
    or die "connect: $!";
$LOOP->run;

ok(!$STATE->{error}, 'accept succeeds without Stream error');
is($listener->accepted, 1, 'accepted counter advances');
is($STATE->{accepted_stream}, $STATE->{stream},
    'on_accept receives the constructed Stream');
is($STATE->{accept_loop}, $LOOP,
    'on_accept receives Stream after Loop attachment');
is_deeply($STATE->{order}, [qw(accept ready)],
    'Listener on_accept precedes plain Stream on_ready');
is($STATE->{peer}->family, 'inet', 'accepted peer reports IPv4');
is($STATE->{peer}->host, '127.0.0.1', 'accepted peer reports loopback host');
ok($STATE->{peer}->port > 0, 'accepted peer reports client port');
ok($STATE->{status_flags} & O_NONBLOCK, 'accept4 sets nonblocking atomically');
ok($STATE->{fd_flags} & FD_CLOEXEC, 'accept4 sets close-on-exec atomically');
ok($STATE->{written}, 'accepted Stream writes immediately');
is(sysread($client, my $bytes, 2), 2, 'client receives Stream output');
is($bytes, 'ok', 'accepted connection carries bytes');

$listener->pause;
ok($listener->is_paused, 'pause disables accepting');
$listener->resume;
is($listener->state, 'listening', 'resume restores accepting');
$STATE->{stream}->close;
$listener->close;
is($listener->state, 'closed', 'close ends Listener lifecycle');
ok(!defined($listener->fd), 'owned listener socket is closed');

close $client;
done_testing;
