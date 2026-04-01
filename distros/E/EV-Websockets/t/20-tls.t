use strict;
use warnings;
use Test::More;
use POSIX ();
use File::Temp ();
use EV;
use EV::Websockets;

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Check openssl availability
my $openssl = `openssl version 2>&1`;
plan skip_all => 'openssl not available' unless $? == 0 && $openssl =~ /OpenSSL|LibreSSL/i;

# Generate self-signed cert+key
my $cert_file = File::Temp->new(SUFFIX => '.pem', UNLINK => 1);
my $key_file  = File::Temp->new(SUFFIX => '.pem', UNLINK => 1);

system('openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
    '-keyout', $key_file->filename, '-out', $cert_file->filename,
    '-days', '1', '-subj', '/CN=localhost',
    '-batch', '-quiet') == 0
    or plan skip_all => 'failed to generate self-signed certificate';

my $ctx = EV::Websockets::Context->new();

my ($connected, $srv_msg, $cli_msg, $closed);
my %keep;

my $port = $ctx->listen(
    port     => 0,
    ssl_cert => $cert_file->filename,
    ssl_key  => $key_file->filename,
    on_connect => sub {
        $keep{srv} = $_[0];
        diag "Server: TLS connection established" if $ENV{EV_WS_DEBUG};
    },
    on_message => sub {
        $srv_msg = $_[1];
        $_[0]->send("echo:$_[1]");
    },
    on_close => sub { delete $keep{srv} },
);

diag "TLS server listening on port $port";

my $start = EV::timer(0.1, 0, sub {
    $keep{cli} = $ctx->connect(
        url        => "wss://127.0.0.1:$port",
        ssl_verify => 0,
        on_connect => sub {
            $connected = 1;
            $_[0]->send("hello tls");
        },
        on_message => sub {
            $cli_msg = $_[1];
            $_[0]->close(1000);
        },
        on_close => sub {
            $closed = 1;
            delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error => sub {
            diag "Client error: $_[1]";
            delete $keep{cli};
            EV::break;
        },
    );
});

my $timeout = EV::timer(5, 0, sub { diag "Timeout"; EV::break });
EV::run;

ok($connected,                          "TLS connection established");
is($srv_msg, "hello tls",              "server received message over TLS");
is($cli_msg, "echo:hello tls",        "client received echo over TLS");
ok($closed,                             "close completed");

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
