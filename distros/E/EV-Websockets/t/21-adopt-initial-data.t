use strict;
use warnings;
use Test::More;
use POSIX ();
use IO::Socket::INET;
use EV;
use EV::Websockets;

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

my $ctx = EV::Websockets::Context->new();

# Vhost required for adopt()
$ctx->listen(port => 0, on_connect => sub {}, on_message => sub {});

# Raw TCP listener (stand-in for Feersum/nginx/etc.)
my $raw_srv = IO::Socket::INET->new(
    Listen    => 5,
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    ReuseAddr => 1,
    Blocking  => 0,
) or die "raw listener: $!";
my $port = $raw_srv->sockport;

my ($adopted_ok, $srv_msg, $cli_msg);
my %keep;

# Watch for incoming connection on raw listener
$keep{accept_w} = EV::io($raw_srv, EV::READ, sub {
    my $accepted = $raw_srv->accept or return;
    $accepted->blocking(0);

    # Read the HTTP upgrade request the WS client sent
    $keep{read_w} = EV::io($accepted, EV::READ, sub {
        delete $keep{read_w};
        my $buf;
        my $n = $accepted->sysread($buf, 8192);
        unless ($n && $n > 0) {
            diag "sysread failed: " . ($! || "EOF");
            EV::break;
            return;
        }
        diag "Raw server read $n bytes" if $ENV{EV_WS_DEBUG};

        # Hand off to lws via adopt() with the bytes we already consumed
        eval {
            $keep{ws} = $ctx->adopt(
                fh           => $accepted,
                initial_data => $buf,
                on_connect   => sub { $adopted_ok = 1 },
                on_message   => sub {
                    $srv_msg = $_[1];
                    $_[0]->send("echo:$_[1]");
                },
                on_close => sub { delete $keep{ws} },
                on_error => sub { delete $keep{ws} },
            );
        };
        diag "adopt failed: $@" if $@;
    });
    delete $keep{accept_w};
});

# WS client connects to the raw TCP port (not a WS server)
$keep{cli} = $ctx->connect(
    url => "ws://127.0.0.1:$port/test",
    on_connect => sub { $_[0]->send("hello adopt") },
    on_message => sub {
        $cli_msg = $_[1];
        $_[0]->close(1000);
    },
    on_close => sub {
        delete $keep{cli};
        EV::break;
    },
    on_error => sub {
        diag "client error: $_[1]";
        delete $keep{cli};
        EV::break;
    },
);

my $timeout = EV::timer(5, 0, sub { diag "Timeout"; EV::break });
EV::run;

ok($adopted_ok,                            "adopted connection established");
is($srv_msg, "hello adopt",               "server received message via adopt");
is($cli_msg, "echo:hello adopt",          "client received echo via adopt");

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
