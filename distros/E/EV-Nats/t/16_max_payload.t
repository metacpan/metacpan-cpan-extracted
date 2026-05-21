use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Nats;

my $host = $ENV{TEST_NATS_HOST} || '127.0.0.1';
my $port = $ENV{TEST_NATS_PORT} || 4222;

my $sock = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 1);
plan skip_all => "NATS server not available at $host:$port" unless $sock;
close $sock;

plan tests => 6;

my $nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_" },
    on_connect => sub { EV::break },
);
EV::timer(5, 0, sub { EV::break });
EV::run;

ok $nats->is_connected, 'connected';

# Set a tiny ceiling so we can test the croak without sending huge payloads.
$nats->max_payload(8);
is $nats->max_payload, 8, 'max_payload override applied';

my $small  = 'x' x 4;    # under limit
my $big    = 'x' x 16;   # over limit
my $hdr    = "NATS/1.0\r\n\r\n";  # 13 bytes; counts toward the limit too

# publish: under limit ok, over limit croaks
eval { $nats->publish('mp.test', $small) };
is $@, '', 'publish under limit ok';

eval { $nats->publish('mp.test', $big) };
like $@, qr/exceeds max_payload/, 'publish over limit croaks';

# hpublish: header + body must fit
eval { $nats->hpublish('mp.test', $hdr, '') };
like $@, qr/exceeds max_payload/, 'hpublish over limit croaks (header alone)';

# request: must enforce the same ceiling
eval { $nats->request('mp.test', $big, sub {}, 1000) };
like $@, qr/exceeds max_payload/, 'request over limit croaks';

$nats->disconnect;
