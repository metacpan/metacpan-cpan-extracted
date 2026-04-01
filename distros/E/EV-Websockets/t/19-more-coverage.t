use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# 10. Client-side max_message_size -- server sends oversized message
{
    my $ctx = EV::Websockets::Context->new();
    my ($cli_error, $cli_error_msg);
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub {
            my ($c, $data) = @_;
            # Server sends a large message that exceeds client's max
            $c->send("x" x 512);
        },
        on_close => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url              => "ws://127.0.0.1:$port",
            max_message_size => 64,
            on_connect => sub {
                my ($c) = @_;
                # Trigger the server to send oversized response
                $c->send("go");
            },
            on_message => sub { },
            on_error => sub {
                my ($c, $err) = @_;
                $cli_error = 1;
                $cli_error_msg = $err;
            },
            on_close => sub {
                delete $keep{cli};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
        );
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($cli_error, "client on_error fired for oversized message");
    like($cli_error_msg || '', qr/max_message_size/,
         "error mentions max_message_size (got: " . ($cli_error_msg // 'undef') . ")");
}

# 11. Pause/resume on server side
{
    my $ctx = EV::Websockets::Context->new();
    my @srv_received;
    my $cli_done = 0;
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub {
            my ($c) = @_;
            $keep{srv} = $c;
            # Pause receiving immediately
            $c->pause_recv;
            # Resume after a delay
            my $t; $t = EV::timer(0.5, 0, sub {
                undef $t;
                $c->resume_recv;
            });
        },
        on_message => sub {
            my ($c, $data) = @_;
            push @srv_received, $data;
            $c->send("ack:$data");
        },
        on_close => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                my ($c) = @_;
                # Send while server is paused
                $c->send("while_paused");
            },
            on_message => sub {
                my ($c, $data) = @_;
                $cli_done = 1;
                $c->close(1000);
            },
            on_close => sub {
                delete $keep{cli};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { delete $keep{cli}; EV::break },
        );
    });

    my $to = EV::timer(15, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($cli_done, "client received ack after server resume");
    is(scalar @srv_received, 1, "server received exactly 1 message after resume");
    is($srv_received[0], "while_paused",
       "server received message that was sent while paused");
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
