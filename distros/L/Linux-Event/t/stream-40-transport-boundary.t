use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::IO::Pipe;
use Linux::Event::IO::Sock::Stream;

{
    package T::TransportOne;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        $stream->data->{input} .= $bytes;
        $stream->loop->stop;
    }
}

{
    package T::TransportTwo;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { }
}

{
    package T::TransportPipe;
    use parent 'Linux::Event::IO::Pipe';
    sub on_data ($stream, $bytes) { }
}

socketpair(my $stream_fh, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";

my $loop = Linux::Event::Loop->new;
my $state = { input => '' };
my $stream = T::TransportOne->new(
    loop => $loop,
    fh   => $stream_fh,
    data => $state,
);

is($stream->transport_name, 'plain',
    'ordinary Stream reports the native plain transport');
ok(!defined $stream->transport,
    'ordinary Stream has no adjacent provider object');
ok($stream->is_transport_ready,
    'ordinary Stream transport is immediately ready');

syswrite($peer, 'in') == 2 or die "peer syswrite: $!";
$loop->run;
is($state->{input}, 'in', 'plain transport feeds the existing input engine');

ok($stream->write('out'), 'plain transport accepts immediate output');
my $output = '';
sysread($peer, $output, 3) == 3 or die "peer sysread: $!";
is($output, 'out', 'plain transport drains the existing output engine');

$stream->transition_to('T::TransportTwo');
is($stream->transport_name, 'plain',
    'protocol transition retains the connection transport');

my $ok = eval { $stream->transition_to('T::TransportPipe'); 1 };
ok(!$ok, 'socket stream cannot transition to a pipe protocol');
like($@, qr/cannot change ordered-byte resource kind/,
    'socket-to-pipe rejection identifies the resource boundary');

pipe(my $pipe_read, my $pipe_write) or die "pipe: $!";
my $pipe = T::TransportPipe->new(loop => $loop, read_fh => $pipe_read);
$ok = eval { $pipe->transition_to('T::TransportTwo'); 1 };
ok(!$ok, 'pipe cannot transition to a socket-stream protocol');
like($@, qr/cannot change ordered-byte resource kind/,
    'pipe-to-socket rejection identifies the resource boundary');
$pipe->close;
close $pipe_write;

$stream->end;
my $eof = sysread($peer, my $after_end, 1);
is($eof, 0, 'transport boundary performs writable half-close');

$stream->close;
ok(!defined $stream->transport_name,
    'closed Stream no longer reports a live transport');
close $peer;

done_testing;
