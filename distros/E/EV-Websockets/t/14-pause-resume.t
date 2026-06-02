use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

# Test pause_recv / resume_recv: pause, send, resume, verify delivery

my $ctx = EV::Websockets::Context->new();
my (%keep, @received, $received_during_pause);

my $port = $ctx->listen(
    port => 0,
    on_connect => sub { $keep{srv} = $_[0] },
    on_message => sub {
        my ($c, $data) = @_;
        $c->send("echo:$data");
    },
    on_close => sub { delete $keep{srv} },
);

my $start = EV::timer(0.1, 0, sub {
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            my ($c) = @_;
            # Pause receiving
            $c->pause_recv;
            # Send a message (server will echo, but we won't receive yet)
            $c->send("paused_msg");
            # Resume after delay
            my $t; $t = EV::timer(0.5, 0, sub {
                undef $t;
                # By now the server's echo is sitting in the socket buffer,
                # held back by flow control; nothing should be delivered yet.
                $received_during_pause = scalar @received;
                $c->resume_recv;
            });
        },
        on_message => sub {
            my ($c, $data) = @_;
            push @received, $data;
            $c->close(1000);
        },
        on_close => sub {
            delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error => sub { delete $keep{cli}; EV::break },
    );
});

my $to = EV::timer(15, 0, sub { diag "Timeout"; EV::break });
EV::run;

is($received_during_pause, 0, "nothing delivered while paused (flow control held it)");
is(scalar @received, 1, "received message after resume");
is($received[0], "echo:paused_msg", "message content correct after pause/resume cycle");

done_testing;
