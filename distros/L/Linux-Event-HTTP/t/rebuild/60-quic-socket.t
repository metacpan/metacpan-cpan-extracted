use v5.36;
use Test::More;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Dgram;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::_QUICSocket;

{
    package LocalQUICManager;
    sub new ($class, $loop) { bless { loop => $loop, started => 0, timed_out => 0 }, $class }
    sub start ($self) { ++$self->{started} }
    sub receive ($self, $bytes, $local, $peer) {
        $self->{received} = [$bytes, $local, $peer];
        $self->{loop}->stop;
    }
    sub timeout ($self) { ++$self->{timed_out}; $self->{loop}->stop }
    sub writable ($self) { ++$self->{writable} }
}
{
    package LocalQUICPacket;
    sub new ($class, $data, $local, $peer) { bless [$data, $local, $peer], $class }
    sub data ($self) { $self->[0] }
    sub local ($self) { $self->[1] }
    sub peer ($self) { $self->[2] }
}

my $loop = Linux::Event::Loop->new;
my $bridge = Linux::Event::HTTP::_QUICSocket->new(
    loop => $loop, host => '127.0.0.1', port => 0,
);
my $received;
my $peer = Linux::Event::IO::Sock::Dgram->new(
    loop => $loop, host => '127.0.0.1', port => 0,
    on_datagram => sub ($socket, $bytes, $source) {
        $received = $bytes;
        $loop->stop;
    },
);
my $manager = LocalQUICManager->new($loop);
$bridge->start($manager);
is($manager->{started}, 1, 'QUIC manager is started exactly once');
is($bridge->local, $bridge->socket->local->sockaddr, 'concrete bound local address preserved');

my $send = $bridge->send_callback;
my $timer = $bridge->set_timeout_callback;
my $packet = LocalQUICPacket->new('hello', $bridge->local, $peer->local->sockaddr);
my $guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 3,
    on_timer => sub { die "QUIC UDP send timed out\n" });
ok($send->($packet), 'one datagram accepted for UDP output');
$loop->run;
$guard->cancel;
is($received, 'hello', 'send callback delivers one complete datagram');

$guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 3,
    on_timer => sub { die "QUIC UDP receive timed out\n" });
$peer->send('incoming', to => $bridge->socket->local);
$loop->run;
$guard->cancel;
is($manager->{received}[0], 'incoming', 'UDP input forwarded to manager');
is($manager->{received}[1], $bridge->local, 'receive uses concrete packed local address');
is($manager->{received}[2], $peer->local->sockaddr, 'receive uses packed sender address');

$timer->(10);
$timer->(0.01);
$guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 3,
    on_timer => sub { die "QUIC timer replacement timed out\n" });
$loop->run;
$guard->cancel;
is($manager->{timed_out}, 1, 'latest relative timer fires once');
$timer->('1e-3');
$guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 3,
    on_timer => sub { die "QUIC small timer timed out\n" });
$loop->run;
$guard->cancel;
is($manager->{timed_out}, 2, 'scientific notation fractional seconds accepted');
$timer->(10);
$timer->(undef);
ok(!$bridge->{timer}, 'undef cancels outstanding timer');

my $wrong = LocalQUICPacket->new('wrong', $peer->local->sockaddr, $peer->local->sockaddr);
like(eval { $send->($wrong); 1 } ? '' : $@, qr/different source address/,
    'packets from an unsupported source address fail instead of misrouting');
$bridge->close;
$bridge->close;
$peer->close;
is($loop->count, 0, 'idempotent close releases UDP and timer watchers');
like(eval { $send->($packet); 1 } ? '' : $@, qr/closed/,
    'send after close fails explicitly');

like(eval { Linux::Event::HTTP::_QUICSocket->new(
    loop => $loop, host => '0.0.0.0', port => 0,
); 1 } ? '' : $@, qr/concrete local host/,
    'wildcard binding rejected without per-packet destination addresses');

done_testing;
