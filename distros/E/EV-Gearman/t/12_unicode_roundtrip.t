# Documented contract: payloads are byte-strings. Encode UTF-8 yourself.
# This test pins the byte-identity of an encoded round-trip and
# protects future readers from accidentally adding implicit decode.
use strict;
use warnings;
use utf8;
use Test::More;
use IO::Socket::INET;
use Encode qw(encode_utf8 decode_utf8);
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

my $cli  = EV::Gearman->new(host => $host, port => $port);
my $wkr  = EV::Gearman->new(host => $host, port => $port);
my $func = "u8_test_$$";

# Worker that uppercases via Unicode-aware uc — must encode_utf8 the
# return value to put bytes back on the wire.
$wkr->register_function($func => sub {
    my $bytes = $_[0]->workload;
    my $text  = decode_utf8($bytes);
    return encode_utf8(uc $text);
});
$wkr->work;

my $hellos = "héllo, wörld • 世界 • π = 3.14";
my $bytes_in = encode_utf8($hellos);

my ($r, $e);
$cli->submit_job($func, $bytes_in, sub { ($r, $e) = @_; EV::break });
my $g = EV::timer 5, 0, sub { fail "u8 timeout"; EV::break };
EV::run;

is $e, undef, 'no error';
ok defined($r), 'got bytes back';

is decode_utf8($r), uc $hellos,
    'utf-8 round-trip + worker-side uc preserves content';

# Pin byte length: encode_utf8 of "héllo" is 6 bytes (é = 2 bytes),
# the whole string is multi-byte, length($r) > length($hellos).
ok length($r) > length($hellos),
    "byte length ($r:".length($r).") exceeds char count ".length($hellos);

done_testing;
