use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Kafka;

# In-process mock broker: a localhost listener that replies to ApiVersions
# (the connect handshake) with a hand-crafted response. Verifies that the
# Conn handshake works against bytes we control, without docker.

plan tests => 4;

# Spawn a listener on a free port.
my $server = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen    => 1,
    Proto     => 'tcp',
    ReuseAddr => 1,
) or BAIL_OUT "cannot bind localhost listener: $!";
$server->blocking(0);

my $port = $server->sockport;
note "mock broker listening on 127.0.0.1:$port";

# Build a small ApiVersions response. v0 layout:
#   error_code(i16) + api_versions_array(i32 count, then [api_key, min_ver, max_ver]*)
sub i16 { pack 'n', $_[0] }
sub i32 { pack 'N', $_[0] }
sub i64 { pack 'q>', $_[0] }

my $apis_body =
      i16(0)         # no error
    . i32(2)         # 2 entries
    . i16(0) . i16(0) . i16(7)     # API_PRODUCE, v0..v7
    . i16(18) . i16(0) . i16(0);   # API_API_VERSIONS, v0..v0

# Wrap with response framing: size + correlation_id + body.
sub frame_response {
    my ($corr_id, $body) = @_;
    my $payload = i32($corr_id) . $body;
    return i32(length $payload) . $payload;
}

# Accept the connection and parse the request to recover the correlation id.
my $client_fh;
my @incoming;        # bytes read from client
my $request_corr_id;
my $client_read_w;   # kept alive by closure on the outer lexical

my $accept_w = EV::io fileno($server), EV::READ, sub {
    $client_fh = $server->accept or return;
    $client_fh->blocking(0);
    note "mock broker accepted connection";

    $client_read_w = EV::io fileno($client_fh), EV::READ, sub {
        my $buf;
        my $n = sysread $client_fh, $buf, 4096;
        if (!defined $n || $n == 0) {
            undef $client_read_w;
            return;
        }
        push @incoming, $buf;
        my $all = join '', @incoming;
        # Request: size(i32) + api(i16) + version(i16) + corr(i32) + client_id(string) + ...
        return if length($all) < 4;
        my $size = unpack 'N', substr($all, 0, 4);
        return if length($all) < 4 + $size;
        # Skip api+version
        $request_corr_id = unpack 'N', substr($all, 4 + 2 + 2, 4);
        # Reply with the canned ApiVersions response.
        syswrite $client_fh, frame_response($request_corr_id, $apis_body);
        undef $client_read_w;
    };
};

# Drive the client.
my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
my $connected = 0;
my $errored;
$conn->on_connect(sub { $connected = 1; EV::break });
$conn->on_error(sub { $errored = $_[0]; EV::break });
$conn->connect('127.0.0.1', $port, 5.0);

# Run the loop with a safety timeout.
my $timeout = EV::timer 5, 0, sub {
    diag "mock broker test timed out";
    EV::break;
};
EV::run;

ok !$errored, 'no error during mock handshake' or diag $errored;
ok $connected, 'on_connect fires after canned ApiVersions reply';
ok defined $request_corr_id, 'mock broker observed an ApiVersions request';
ok $conn->connected, 'conn reports ready state';

eval { $conn->disconnect; };
close $server;
