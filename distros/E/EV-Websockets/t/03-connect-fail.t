use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

my $ctx = EV::Websockets::Context->new();
my $connected = 0;
my $failed = 0;

# Connect to a closed port
my $conn = $ctx->connect(
    url => "ws://127.0.0.1:1", 
    on_connect => sub {
        $connected = 1;
        EV::break;
    },
    on_error => sub {
        my ($c, $err) = @_;
        diag "Connection failed as expected: $err";
        $failed = 1;
        EV::break;
    },
);

# Timeout after 2 seconds
EV::timer(2, 0, sub { EV::break; });

EV::run;

ok(!$connected, 'Should not connect to closed port');
ok($failed, 'Should trigger on_error');

done_testing;
