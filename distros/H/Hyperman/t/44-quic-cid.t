#!perl
use strict;
use warnings;
use Test::More;
use Hyperman;

# The QUIC parts that face unauthenticated UDP: the Destination
# Connection ID map, the expiry min-heap, and the packet decoder they sit
# behind.
#
# None of these is reachable through a real client, and two of them fail in
# ways no black-box test would show. A CID-map bug misroutes one client's
# packets into another client's connection, which is a data disclosure rather
# than a crash. A broken heap sift is either a connection that never times
# out or one that PTOs itself to death. So they are driven from C.
#
# Both selftests were mutation-checked while being written: breaking the
# length comparison in the lookup, and making the heap rearm sift only one
# way, each turn the corresponding selftest from 1 to 0.

plan skip_all => 'HTTP/3 support not built' unless Hyperman->has_http3;

is(Hyperman::_quic_cid_selftest(), 1,
   'the CID map: many CIDs over many connections all resolve to their own, '
 . 'retiring a connection takes its CIDs and nothing else, and a prefix '
 . 'sharing a bucket with a longer CID does not match it');

is(Hyperman::_quic_heap_selftest(), 1,
   'the expiry heap: pushes in random order drain monotonically, deadlines '
 . 'move both earlier and later, and every cached index agrees with its slot');

# ---- the decoder ----------------------------------------------------------
#
# ngtcp2_pkt_decode_version_cid is the first thing that touches an
# attacker-controlled datagram. The vectors below are hand-built long and
# short headers; the return codes were read off this library rather than
# quoted from memory, because a remembered constant that happens to be wrong
# passes vacuously.
#
#   0     decoded
#   -201  NGTCP2_ERR_INVALID_ARGUMENT
#   -235  NGTCP2_ERR_VERSION_NEGOTIATION

my $DCID = join('', map chr, 1 .. 16);
my $SCID = join('', map chr, 100 .. 107);

sub long_hdr {
    my ($ver, $dcid, $scid, $pad) = @_;
    my $p = "\xc0" . $ver . chr(length $dcid) . $dcid
                   . chr(length $scid) . $scid;
    $p .= "\x00" x ($pad - length $p) if $pad && $pad > length $p;
    return $p;
}

my @r;

@r = Hyperman::_quic_decode_selftest('');
is($r[0], -1, 'an empty datagram is refused BEFORE ngtcp2 sees it');
# ngtcp2 asserts datalen is non-zero and this build has assertions live, so
# without that guard an empty datagram aborts the worker rather than being
# dropped. hm_quic_readable skips them too; the decoder holds on its own.

@r = Hyperman::_quic_decode_selftest("\xff\x00\x11");
is($r[0], -201, 'three bytes of garbage are refused');

@r = Hyperman::_quic_decode_selftest(long_hdr("\x00\x00\x00\x01", $DCID, $SCID));
is($r[0], 0,          'a QUIC v1 long header decodes');
is($r[1], 1,          '...with the version it carried');
is($r[2], length $DCID, '...and the destination connection id length');
is($r[3], length $SCID, '...and the source connection id length');

@r = Hyperman::_quic_decode_selftest(
        substr(long_hdr("\x00\x00\x00\x01", $DCID, $SCID), 0, 10));
is($r[0], -201, 'a long header truncated mid-connection-id is refused');

@r = Hyperman::_quic_decode_selftest("\x40" . $DCID);
is($r[0], 0, 'a short header decodes');
is($r[1], 0, '...reporting no version, as a short header carries none');
is($r[2], 16, '...and the length the caller said to expect');

# Version negotiation, and the size rule that goes with it. A server must not
# answer a small packet with a larger one, so ngtcp2 asks for a Version
# Negotiation reply only when the datagram was full size - below that an
# unsupported version is simply refused. That is anti-amplification, not a
# quirk, and it is asserted from both sides.
@r = Hyperman::_quic_decode_selftest(
        long_hdr("\x1a\x2b\x3c\x4d", $DCID, $SCID, 1199));
is($r[0], -201, 'an unsupported version in a small datagram is just refused');

@r = Hyperman::_quic_decode_selftest(
        long_hdr("\x1a\x2b\x3c\x4d", $DCID, $SCID, 1200));
is($r[0], -235, 'a full-size datagram asks for Version Negotiation instead');
is($r[1], 0x1a2b3c4d, '...and the fields are filled in, unlike other errors');

# The reason cidlen must be bounded before it is used as a length: for an
# unsupported version the decoder accepts connection ids up to 255 bytes,
# which is far past the 20-byte buffer they would otherwise be compared
# against. This vector is the one that would over-read.
my $BIG = join('', map { chr($_ % 256) } 1 .. 40);
@r = Hyperman::_quic_decode_selftest(long_hdr("\x1a\x2b\x3c\x4d", $BIG, '', 1200));
is($r[0], -235, 'an over-long connection id decodes for version negotiation');
is($r[2], 40,   '...reporting a length of 40, twice NGTCP2_MAX_CIDLEN');
cmp_ok($r[2], '>', 20,
       'so a lookup that trusted this length would read past its buffer');

done_testing();
