use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::IO::Sock::Listener;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

our (@HOOKS, @ERRORS);

{
    package T::ConfiguredServer;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub socket_options ($class) {
        return (
            tcp_nodelay       => 1,
            keepalive         => 1,
            keepalive_idle    => 30,
            keepalive_interval => 5,
            keepalive_count   => 3,
            tcp_user_timeout  => 2.5,
        );
    }
    sub configure_socket ($self, $fh, $role, $address) {
        push @main::HOOKS, [$role, $address->family];
    }
    sub on_data ($self, $bytes) { $self->write($bytes) }
}

{
    package T::ConfiguredClient;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub socket_options ($class) { return tcp_nodelay => 1 }
    sub configure_socket ($self, $fh, $role, $address) {
        push @main::HOOKS, [$role, $address->family];
    }
    sub on_ready ($self) {
        main::is($self->tcp_nodelay, 0,
            'connect constructor overrides class TCP_NODELAY policy');
        main::ok($self->local, 'connected Stream exposes local address');
        main::is($self->local->host, '127.0.0.1',
            'local_host controls outbound source address');
        main::cmp_ok($self->local->port, '>', 0,
            'local_port zero receives an ephemeral port');
        main::is($self->tcp_nodelay(1), 1,
            'TCP_NODELAY can be changed live');
        $self->write("ready\n");
    }
    sub on_data ($self, $bytes) {
        ${ $self->data } = $bytes;
        $self->loop->stop;
    }
}

{
    package T::ConfiguredListener;
    use parent 'Linux::Event::IO::Sock::Listener';
    sub on_accept ($self, $stream) {
        main::is($stream->tcp_nodelay, 1,
            'accepted Stream applies class TCP_NODELAY policy');
        main::is($stream->keepalive, 1,
            'accepted Stream applies keepalive policy');
        main::is($stream->keepalive_idle, 30,
            'accepted Stream applies keepalive idle policy');
        main::is($stream->keepalive_interval, 5,
            'accepted Stream applies keepalive interval policy');
        main::is($stream->keepalive_count, 3,
            'accepted Stream applies keepalive count policy');
        main::is($stream->tcp_user_timeout, 2.5,
            'accepted Stream reports TCP_USER_TIMEOUT in seconds');
    }
    sub on_error ($self, $error) { push @main::ERRORS, $error }
}

my $loop = Linux::Event::Loop->new;
my $listener = $loop->add(T::ConfiguredListener->new(
    stream       => { class => 'T::ConfiguredServer' },
    host         => '127.0.0.1',           # required
    port         => 0,                     # required
));
my $received = '';
my $client = $loop->add(T::ConfiguredClient->connect(
    host        => '127.0.0.1',     # required
    port        => $listener->port, # required
    local_host  => '127.0.0.1',     # optional
    local_port  => 0,               # optional
    tcp_nodelay => 0,               # optional
    data        => \$received,       # optional
));
$loop->run;

is($received, "ready\n", 'configured connection transfers data');
is_deeply(\@HOOKS, [
    ['connect', 'inet'],
    ['accepted', 'inet'],
], 'configure_socket receives acquisition role and address');
is_deeply(\@ERRORS, [], 'socket configuration produced no Listener errors');

$client->close;
$listener->close;

done_testing;
