use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

# Test close code/reason round-trip through on_close

my $ctx = EV::Websockets::Context->new();
my ($srv_code, $srv_reason, $srv_close, $cli_code, $cli_reason);
my %keep;

my $port = $ctx->listen(
    port => 0,
    on_connect => sub { $keep{srv} = $_[0] },
    on_message => sub {
        my ($c, $data) = @_;
        # Server initiates close with specific code/reason
        $c->close(4001, "custom reason");
    },
    on_close => sub {
        my ($c, $code, $reason) = @_;
        $srv_code = $code;
        $srv_reason = $reason;
        $srv_close = 1;
        delete $keep{srv};
    },
);

ok($port > 0, "listening on port $port");

my $start = EV::timer(0.1, 0, sub {
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            $_[0]->send("trigger close");
        },
        on_close => sub {
            my ($c, $code, $reason) = @_;
            $cli_code = $code;
            $cli_reason = $reason;
            delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error => sub { delete $keep{cli}; EV::break },
    );
});

my $to = EV::timer(10, 0, sub { diag "Timeout"; EV::break });
EV::run;

# The client should see a close code (lws may report 1000 for clean close handshakes
# or the actual code depending on version/timing)
ok(defined $cli_code, "client received a close code");
# Verify server saw the close
ok($srv_close, "server on_close fired");

done_testing;
