use v5.36;
use strict;
use warnings;

use Socket qw(AF_UNIX SOCK_STREAM);
use Test::More;

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

sub exception ($code) {
    local $@;
    return eval { $code->(); 1 } ? '' : "$@";
}

{
    package T::BufferSocketStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub socket_options ($class) {
        return send_buffer => 32_768, receive_buffer => 32_768;
    }
    sub on_data ($self, $bytes) { }
}

socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, 0)
    or plan skip_all => "socketpair unavailable: $!";
my $stream = T::BufferSocketStream->new(fh => $left);
cmp_ok($stream->send_buffer, '>=', 32_768,
    'class send buffer policy is applied');
cmp_ok($stream->receive_buffer, '>=', 32_768,
    'class receive buffer policy is applied');
cmp_ok($stream->send_buffer(65_536), '>=', 65_536,
    'send buffer is live settable and returns effective value');
cmp_ok($stream->receive_buffer(65_536), '>=', 65_536,
    'receive buffer is live settable and returns effective value');
is($stream->local->family, 'unix', 'local address is available on adopted socket');
$stream->close;
close $right;

{
    package T::InvalidUnixTCPStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub socket_options ($class) { return tcp_nodelay => 1 }
    sub on_data ($self, $bytes) { }
}

socketpair(my $tcp_left, my $tcp_right, AF_UNIX, SOCK_STREAM, 0)
    or die "socketpair: $!";
like(exception(sub { T::InvalidUnixTCPStream->new(fh => $tcp_left) }),
    qr/tcp_nodelay is valid only for TCP sockets/,
    'TCP-only class policy is rejected for Unix sockets');
close $tcp_right;

{
    package T::InvalidSocketOption;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub socket_options ($class) { return keepalive => 2 }
    sub on_data ($self, $bytes) { }
}
like(exception(sub { T::InvalidSocketOption->_validate_accepted_configuration }),
    qr/keepalive must be zero or one/,
    'invalid class socket option fails descriptor construction');

{
    package T::FailingSocketConfiguration;
    use parent 'Linux::Event::IO::Sock::Stream';
    our $CLOSE_CALLS = 0;
    sub on_data ($self, $bytes) { }
    sub configure_socket ($self, $fh, $role, $peer) { die "synthetic failure\n" }
    sub close ($self) { ++$CLOSE_CALLS; return $self }
}

socketpair(my $failed_left, my $failed_right, AF_UNIX, SOCK_STREAM, 0)
    or die "socketpair: $!";
like(exception(sub { T::FailingSocketConfiguration->new(fh => $failed_left) }),
    qr/configure_socket: synthetic failure/,
    'configure_socket failure propagates as a typed setup error');
is($T::FailingSocketConfiguration::CLOSE_CALLS, 0,
    'forced constructor cleanup bypasses subclass close override');
ok(!defined(fileno($failed_left)),
    'configure_socket failure closes the adopted descriptor');
close $failed_right;

{
    package T::BrokenStreamLoop;
    sub new ($class) { bless {}, $class }
    sub add ($self, $object) { $object->_attach_to_loop($self) }
    sub watch ($self, @option) { die "synthetic Stream watch failure\n" }
    sub watch_fd ($self, @option) { die "synthetic Stream watch failure\n" }
}

socketpair(my $retry_left, my $retry_right, AF_UNIX, SOCK_STREAM, 0)
    or die "socketpair: $!";
my $retry_stream = T::BufferSocketStream->new(fh => $retry_left);
like(exception(sub { T::BrokenStreamLoop->new->add($retry_stream) }),
    qr/synthetic Stream watch failure/,
    'Stream registration failure propagates');
is($retry_stream->state, 'unattached',
    'failed Stream registration leaves the object attachable');
my $retry_loop = Linux::Event::Loop->new;
is($retry_loop->add($retry_stream), $retry_stream,
    'Stream can attach after a failed registration attempt');
$retry_stream->close;
close $retry_right;

done_testing;
