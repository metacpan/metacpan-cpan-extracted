use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

# Test error paths: invalid URL, missing params, double close

my $ctx = EV::Websockets::Context->new();

# Missing url
eval { $ctx->connect(on_message => sub {}) };
like($@, qr/url parameter is required/, "connect without url croaks");

# Reserved vhost name
eval { $ctx->listen(port => 0, name => 'default') };
like($@, qr/reserved/, "listen with name 'default' croaks");

# Invalid URL scheme
eval { $ctx->connect(url => "http://example.com") };
like($@, qr/URL must start with ws:\/\/ or wss:\/\//, "connect with http:// croaks");

# adopt() input validation
eval { $ctx->adopt(on_message => sub {}) };
like($@, qr/fh parameter is required/, "adopt without fh croaks");

{
    open(my $fh, '<', '/dev/null') or die "open: $!";
    close $fh;  # closed handle has no valid fileno
    eval { $ctx->adopt(fh => $fh, on_message => sub {}) };
    like($@, qr/Invalid filehandle/, "adopt with closed handle croaks");
}

# Double close should not crash
my %keep;
my $double_close_ok;

my $port = $ctx->listen(
    port => 0,
    on_connect => sub { $keep{srv} = $_[0] },
    on_message => sub { $_[0]->send("ack") },
    on_close => sub { delete $keep{srv} },
);

my $start = EV::timer(0.1, 0, sub {
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub { $_[0]->send("hi") },
        on_message => sub {
            my ($c) = @_;
            $c->close(1000);
            # Double close — should not crash (silently returns)
            $c->close(1000);
            $double_close_ok = 1;
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

ok($double_close_ok, "double close did not crash");

done_testing;
