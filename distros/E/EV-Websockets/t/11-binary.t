use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

# Test binary message round-trip with is_binary flag verification

my $ctx = EV::Websockets::Context->new();
my ($srv_data, $srv_is_binary, $cli_data, $cli_is_binary);
my %keep;

my $port = $ctx->listen(
    port => 0,
    on_connect => sub { $keep{srv} = $_[0] },
    on_message => sub {
        my ($c, $data, $is_binary) = @_;
        $srv_data = $data;
        $srv_is_binary = $is_binary;
        # Echo back as binary
        $c->send_binary($data);
    },
    on_close => sub { delete $keep{srv} },
);

my $binary_payload = join('', map { chr($_) } 0..255);

my $start = EV::timer(0.1, 0, sub {
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            $_[0]->send_binary($binary_payload);
        },
        on_message => sub {
            my ($c, $data, $is_binary) = @_;
            $cli_data = $data;
            $cli_is_binary = $is_binary;
            $c->close(1000);
        },
        on_close => sub {
            delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error => sub { delete $keep{cli}; EV::break },
    );
});

my $to = EV::timer(10, 0, sub { diag "Timeout"; EV::break });
EV::run;

is($srv_is_binary, 1, "server on_message sees is_binary=1");
is(length($srv_data), 256, "server received full binary payload");
is($cli_is_binary, 1, "client on_message sees is_binary=1 on echo");
is($cli_data, $binary_payload, "binary data round-trip is lossless");

done_testing;
