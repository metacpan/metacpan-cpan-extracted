use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Feersum; 1 }
        or plan skip_all => 'Feersum not installed';
}

use POSIX ();
use EV;
use EV::Websockets;
use IO::Socket::INET;

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Test: Feersum accepts HTTP, detects WS upgrade, hands the socket
# to EV::Websockets adopt() with reconstructed HTTP upgrade as initial_data.

my $ctx = EV::Websockets::Context->new();

my $feersum = Feersum->endjinn;
my $sock = IO::Socket::INET->new(
    Listen => 10, LocalAddr => '127.0.0.1', LocalPort => 0,
    ReuseAddr => 1, Blocking => 0,
) or die "Socket: $!";

my $port = $sock->sockport;
$feersum->use_socket($sock);

my (%keep, $handler_fired, $adopted_ok, $srv_msg, $cli_msg);

$feersum->request_handler(sub {
    my $req = shift;
    my $env = $req->env;
    $handler_fired = 1;

    unless (($env->{HTTP_UPGRADE} // '') =~ /websocket/i) {
        $req->send_response(400, [], ["Not a WebSocket"]);
        return;
    }

    my $io = $req->io;

    my $path = $env->{REQUEST_URI} // $env->{PATH_INFO} // '/';
    my $http_req = "GET $path HTTP/1.1\r\n";
    for my $key (sort keys %$env) {
        next unless $key =~ /^HTTP_(.+)/;
        (my $hdr = $1) =~ s/_/-/g;
        $http_req .= "$hdr: $env->{$key}\r\n";
    }
    $http_req .= "\r\n";

    eval {
        $keep{ws} = $ctx->adopt(
            fh           => $io,
            initial_data => $http_req,
            on_connect => sub { $adopted_ok = 1 },
            on_message => sub {
                $srv_msg = $_[1];
                $_[0]->send("echo:$_[1]");
            },
            on_close => sub { delete $keep{ws} },
            on_error => sub { delete $keep{ws} },
        );
    };
    diag "adopt failed: $@" if $@;
});

$keep{cli} = $ctx->connect(
    url => "ws://127.0.0.1:$port/ws",
    on_connect => sub { $_[0]->send("hello via feersum") },
    on_message => sub {
        $cli_msg = $_[1];
        $_[0]->close(1000);
    },
    on_close => sub {
        delete $keep{cli};
        my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
    },
    on_error => sub {
        diag "client error: $_[1]";
        delete $keep{cli};
        EV::break;
    },
);

my $timeout = EV::timer(10, 0, sub { diag "Timeout"; EV::break });
EV::run;

ok($handler_fired, "Feersum received WebSocket upgrade request");
ok($adopted_ok, "WebSocket handshake completed via adopt(initial_data)");
is($srv_msg, "hello via feersum", "server received message via adopted connection");
is($cli_msg, "echo:hello via feersum", "client received echo via adopted connection");

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
