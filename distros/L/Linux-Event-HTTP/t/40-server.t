use v5.36;
use strict;
use warnings;

use Test::More;
use Socket qw(AF_INET SOCK_STREAM inet_aton pack_sockaddr_in);

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::HTTP::Server::Connection;
use Linux::Event::HTTP::Server;

sub run_client ($loop, $server, $wire, $state) {
    my $guard = Linux::Event::Kernel::Timer->new(
        loop  => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "HTTP Server integration test timed out\n";
        },
    );

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write($wire);
        },
        on_data => sub ($stream, $bytes) {
            $state->{wire} .= $bytes;
        },
        on_eof => sub ($stream) {
            $guard->cancel;
            $stream->close;
            $server->close;
            $loop->stop;
        },
        on_error => sub ($stream, $error) {
            die "HTTP Server client failed: $error\n";
        },
    );

    $loop->run;
    return;
}

my $loop = Linux::Event::Loop->new;
my $state = {
    body => '',
    wire => '',
};
my $prefix = 'body=';

my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $state,
    tuning => {
        read_budget_bytes => 123,
    },
    on_ready => sub ($conn) {
        $state->{ready_class} = ref($conn);
        $state->{read_budget_bytes}
            = $conn->{xs_state}->stats->{read_budget_bytes};
    },
    on_request => sub ($conn, $req, $res) {
        $state->{request_class} = ref($req);
        $state->{response_class} = ref($res);
        $state->{connection_class} = ref($conn);
        $state->{same_data} = $conn->data == $state ? 1 : 0;
        $res->header('Content-Type', 'text/plain');
    },
    on_body => sub ($conn, $req, $res, $bytes) {
        $state->{body} .= $bytes;
    },
    on_request_end => sub ($conn, $req, $res) {
        $res->body($prefix . $state->{body} . "\n");
    },
);

ok($server->is_tcp, 'Server exposes underlying TCP listener identity');
ok($server->port > 0, 'Server reports kernel-selected listener port');
is(
    $server->connection_class,
    'Linux::Event::HTTP::Server::Connection',
    'Server defaults to HTTP Connection class',
);
is($server->data, $state, 'Server exposes application data, not private accept state');

run_client(
    $loop,
    $server,
    "POST /upload HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Content-Length: 4\r\n" .
        "Connection: close\r\n" .
        "\r\n" .
        "data",
    $state,
);

is($state->{body}, 'data', 'Server forwards request body callback directly');
ok($state->{same_data}, 'accepted Connection receives Server application data');
is(
    $state->{connection_class},
    'Linux::Event::HTTP::Server::Connection',
    'Listener constructs the configured Connection class directly',
);
is($state->{ready_class}, 'Linux::Event::HTTP::Server::Connection',
    'accepted lifecycle callbacks receive the HTTP Connection directly');
is($state->{read_budget_bytes}, 123,
    'Server tuning is applied to accepted HTTP Connections');
is(
    $state->{request_class},
    'Linux::Event::HTTP::Request',
    'Server callback receives Request object',
);
is(
    $state->{response_class},
    'Linux::Event::HTTP::Response',
    'Server callback receives bound Response object',
);
like(
    $state->{wire},
    qr/\AHTTP\/1\.1 200 OK\r\nContent-Type: text\/plain\r\nContent-Length: 10\r\nConnection: close\r\n\r\nbody=data\n\z/s,
    'simple Server callback form produces complete HTTP response',
);

{
    package T::ServerConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $req, $res) {
        $self->data->{class_method_hits}++;
        $self->data->{actual_class} = ref($self);
        $res->body("class\n");
    }
}

$loop = Linux::Event::Loop->new;
my $custom = {
    wire => '',
    class_method_hits => 0,
};

$server = Linux::Event::HTTP::Server->new(
    loop             => $loop,
    host             => '127.0.0.1',
    port             => 0,
    data             => $custom,
    connection_class => 'T::ServerConnection',
);

run_client(
    $loop,
    $server,
    "GET /class HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: close\r\n" .
        "\r\n",
    $custom,
);

is($custom->{class_method_hits}, 1,
    'custom connection_class method handles accepted request');
is($custom->{actual_class}, 'T::ServerConnection',
    'accepted object is the configured custom Connection class');
like($custom->{wire}, qr/\r\n\r\nclass\n\z/s,
    'custom Connection response is delivered through Server');

$loop = Linux::Event::Loop->new;
my $override = {
    wire => '',
    class_method_hits => 0,
    callback_hits => 0,
};

$server = Linux::Event::HTTP::Server->new(
    loop             => $loop,
    host             => '127.0.0.1',
    port             => 0,
    data             => $override,
    connection_class => 'T::ServerConnection',
    on_request => sub ($conn, $req, $res) {
        $override->{callback_hits}++;
        $override->{actual_class} = ref($conn);
        $res->body("override\n");
    },
);

run_client(
    $loop,
    $server,
    "GET /override HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: close\r\n" .
        "\r\n",
    $override,
);

is($override->{callback_hits}, 1,
    'Server constructor callback runs on custom connection_class');
is($override->{class_method_hits}, 0,
    'constructor callback overrides same-named Connection method');
is($override->{actual_class}, 'T::ServerConnection',
    'callback override retains configured Connection subclass');
like($override->{wire}, qr/\r\n\r\noverride\n\z/s,
    'callback override response is delivered');

my $ok = eval {
    Linux::Event::HTTP::Server->new(
        loop => Linux::Event::Loop->new,
        host => '127.0.0.1',
        port => 0,
    );
    1;
};
ok(!$ok, 'default Server requires on_request callback');
like($@, qr/requires on_request/, 'missing handler error is clear');

$ok = eval {
    Linux::Event::HTTP::Server->new(
        loop => Linux::Event::Loop->new,
        host => '127.0.0.1',
        port => 0,
        on_request => sub ($conn, $req, $res) { $res->body("ok\n") },
        on_request_final => sub { return "old\n" },
    );
    1;
};
ok(!$ok, 'Server rejects removed on_request_final option');
like($@, qr/on_request_final was removed/, 'Server gives migration guidance');

$ok = eval {
    Linux::Event::HTTP::Server->new(
        loop => Linux::Event::Loop->new,
        host => '127.0.0.1',
        port => 0,
        on_request => sub { },
        on_data => sub { },
    );
    1;
};
ok(!$ok, 'Server rejects raw on_data callback');
like($@, qr/owns on_data/, 'raw callback rejection explains HTTP ownership');

$ok = eval {
    Linux::Event::HTTP::Server->new(
        loop => Linux::Event::Loop->new,
        host => '127.0.0.1',
        port => 0,
        on_request => sub { },
        on_listener_error => 'not a callback',
    );
    1;
};
ok(!$ok, 'Server validates the distinct Listener error callback');
like($@, qr/on_listener_error must be a coderef/,
    'Listener callback validation names on_listener_error');

{
    package T::RejectedServerConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub configure_socket ($self, $fh, $role, $address) {
        die "intentional accepted socket rejection\n";
    }

    sub on_request ($self, $req, $res) {
        $res->body("unreachable\n");
    }
}

$loop = Linux::Event::Loop->new;
my $errors = {
    connection => 0,
    listener   => 0,
};
$server = Linux::Event::HTTP::Server->new(
    loop             => $loop,
    host             => '127.0.0.1',
    port             => 0,
    connection_class => 'T::RejectedServerConnection',
    on_error => sub ($conn, $error) {
        $errors->{connection}++;
    },
    on_listener_error => sub ($listener, $error) {
        $errors->{listener}++;
        $errors->{error} = $error;
        $loop->stop;
    },
);

my $error_guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 2,
    on_timer => sub ($timer) {
        die "HTTP Server listener error test timed out\n";
    },
);

socket(my $peer, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
connect(
    $peer,
    pack_sockaddr_in($server->port, inet_aton('127.0.0.1')),
) or die "connect: $!";

$loop->run;
$error_guard->cancel;
close $peer;
$server->close;

is($errors->{listener}, 1,
    'accepted setup failure invokes on_listener_error');
is($errors->{connection}, 0,
    'accepted setup failure does not invoke Connection on_error');
isa_ok($errors->{error}, 'Linux::Event::Error');
like("$errors->{error}", qr/intentional accepted socket rejection/,
    'Listener error retains accepted setup failure detail');

done_testing;
