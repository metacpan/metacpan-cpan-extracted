use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::WebSocket::Server;

my $port = 12345 + int(rand(1000));
my $cv = AnyEvent->condvar;
my %server_conns;

# Use robust AnyEvent::WebSocket::Server for data tests
my $server = AnyEvent::WebSocket::Server->new;
my $tcp_server = tcp_server undef, $port, sub {
    my ($fh) = @_;
    $server->establish($fh)->cb(sub {
        my $connection = eval { shift->recv };
        return warn $@ if $@;
        my $id = "$connection";
        $server_conns{$id} = $connection;
        $connection->on(each_message => sub {
            my ($conn, $msg) = @_;
            $conn->send($msg);
        });
        $connection->on(finish => sub { delete $server_conns{$id} });
    });
};

my $ctx = EV::Websockets::Context->new();
my $conn;

my $results = {
    connected => 0,
    text_ok => 0,
    binary_ok => 0,
    states => [],
};

$conn = $ctx->connect(
    url => "ws://127.0.0.1:$port",
    on_connect => sub {
        my ($c, $headers) = @_;
        $results->{connected} = 1;
        push @{$results->{states}}, $c->state;
        $c->send("Perl Rules");
    },
    on_message => sub {
        my ($c, $data, $is_binary) = @_;
        if (!$is_binary) {
            $results->{text_ok} = 1 if $data eq "Perl Rules";
            $c->send_binary(pack "C*", 1, 2, 3, 4);
        } else {
            my @bytes = unpack "C*", $data;
            $results->{binary_ok} = 1 if join(",", @bytes) eq "1,2,3,4";
            $c->send_ping("ping");
            $c->close(1000, "Finalizing");
        }
    },
    on_close => sub {
        my ($c) = @_;
        push @{$results->{states}}, $c->state;
        $cv->send;
    },
    on_error => sub {
        diag "Unexpected error: $_[1]";
        $cv->send;
    }
);

push @{$results->{states}}, $conn->state if $conn->is_connecting;

# Timeout
my $t = EV::timer(10, 0, sub { $cv->send });

$cv->recv;

ok($results->{connected}, 'Connection established');
ok($results->{text_ok}, 'Text message echoed correctly');
ok($results->{binary_ok}, 'Binary message echoed correctly');

# Verify state sequence
my $states = join(",", @{$results->{states}});
like($states, qr/connecting/, 'State sequence included connecting');
like($states, qr/connected/, 'State sequence included connected');
like($states, qr/closed|closing/, 'State sequence ended in closing/closed');

done_testing;
