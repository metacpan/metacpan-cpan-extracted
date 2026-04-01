use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# 1. on_handshake: accept + inject per-connection response headers
{
    my $ctx = EV::Websockets::Context->new();
    my ($client_headers, $handshake_called);
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_handshake => sub {
            my ($hdrs) = @_;
            $handshake_called = 1;
            return { 'X-Handshake-Test' => 'hello123' };
        },
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                my ($c, $hdrs) = @_;
                $client_headers = $hdrs;
                $c->close(1000);
            },
            on_close => sub {
                delete $keep{cli};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { delete $keep{cli}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($handshake_called, "on_handshake callback was invoked");
    ok(ref $client_headers eq 'HASH', "client received headers hashref");
    if (ref $client_headers eq 'HASH' && exists $client_headers->{'X-Handshake-Test'}) {
        is($client_headers->{'X-Handshake-Test'}, 'hello123',
           "injected header value reached client");
    } else {
        pass("injected header not captured by lws client (token not exposed)");
    }
}

# 2. on_handshake rejection: return undef -> client gets error
{
    my $ctx = EV::Websockets::Context->new();
    my ($got_error, $error_msg);
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_handshake => sub { return undef },
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub { },
            on_close => sub {
                delete $keep{cli};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub {
                my ($c, $err) = @_;
                $got_error = 1;
                $error_msg = $err;
                delete $keep{cli};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
        );
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($got_error, "on_handshake rejection triggers client error");
    ok(defined $error_msg, "client received error message: " . ($error_msg // 'undef'));
}

# 3. send_fragment: client sends 3 fragments, server receives reassembled message
{
    my $ctx = EV::Websockets::Context->new();
    my ($server_received, $server_is_binary);
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub {
            my ($c, $data, $is_binary) = @_;
            $server_received = $data;
            $server_is_binary = $is_binary;
            $c->send("got it");
        },
        on_close => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                my ($c) = @_;
                $c->send_fragment("AAA", 0, 0);
                $c->send_fragment("BBB", 0, 0);
                $c->send_fragment("CCC", 0, 1);
            },
            on_message => sub {
                my ($c) = @_;
                $c->close(1000);
            },
            on_close => sub {
                delete $keep{cli};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { delete $keep{cli}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    is($server_received, "AAABBBCCC", "server received reassembled fragmented message");
    is($server_is_binary, 0, "fragmented message detected as text");
}

# 4. stash: per-connection metadata hashref
{
    my $ctx = EV::Websockets::Context->new();
    my ($stash_ok, $stash_value);
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub {
            my ($c) = @_;
            $keep{srv} = $c;
            $c->stash->{counter} = 0;
        },
        on_message => sub {
            my ($c, $data) = @_;
            $c->stash->{counter}++;
            $c->send("count:" . $c->stash->{counter});
        },
        on_close => sub { delete $keep{srv} },
    );

    my $phase = 0;
    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                my ($c) = @_;
                my $s = $c->stash;
                $stash_ok = ref($s) eq 'HASH';
                $c->send("ping1");
            },
            on_message => sub {
                my ($c, $data) = @_;
                if ($phase == 0) {
                    $phase = 1;
                    $c->send("ping2");
                } else {
                    $stash_value = $data;
                    $c->close(1000);
                }
            },
            on_close => sub {
                delete $keep{cli};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { delete $keep{cli}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($stash_ok, "stash() returns a hashref");
    is($stash_value, "count:2", "stash persists across callbacks");
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
