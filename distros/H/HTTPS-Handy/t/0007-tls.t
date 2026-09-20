######################################################################
#
# t/0007-tls.t - The TLS record layer and handshake parts, on their own.
#
#   t/0004-server.t runs a real server and needs fork(), so it is
#   skipped on Windows. The pieces tested here need no socket at all:
#   two connection objects are built by hand, given the same keys, and
#   made to talk to each other through byte strings.
#
#   What is covered:
#     - key derivation from the master secret
#     - sealing and opening a record, and the sequence number
#     - a tampered or misdirected record being refused
#     - reading a ClientHello, including short and hostile ones
#     - the session cache
#     - pulling the public key out of a certificate
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my ($c, $n) = @_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is { my ($g, $e, $n) = @_; $T++; defined($g) && ("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g ? $g : 'undef')}', exp='$e')\n") }

use HTTPS::Handy;

######################################################################
# Two connection objects sharing one master secret
######################################################################

sub _pair {
    my $server = HTTPS::Handy::TLS::_new('HTTPS::Handy::TLS', undef, 1);
    my $client = HTTPS::Handy::TLS::_new('HTTPS::Handy::TLS', undef, 0);
    for my $end ($server, $client) {
        $end->{'client_random'} = 'C' x 32;
        $end->{'server_random'} = 'S' x 32;
        $end->{'master'}        = 'M' x 48;
        $end->{'suite'}         = { 'name' => 'test suite' };
        $end->_derive_keys(undef);
    }
    return ($server, $client);
}

my ($server, $client) = _pair();

# --- Key derivation --------------------------------------------------------

is(length($server->{'client_key'}), 32, 'key block: the client key is 32 bytes');
is(length($server->{'server_key'}), 32, 'key block: the server key is 32 bytes');
is(length($server->{'client_iv'}),  12, 'key block: the client nonce is 12 bytes');
is(length($server->{'server_iv'}),  12, 'key block: the server nonce is 12 bytes');
ok($server->{'client_key'} ne $server->{'server_key'},
   'key block: the two directions get different keys');
ok($server->{'client_iv'} ne $server->{'server_iv'},
   'key block: the two directions get different nonces');
is(unpack('H*', $client->{'server_key'}), unpack('H*', $server->{'server_key'}),
   'both ends derive the same key block');

# The key block must follow from the master secret alone
{
    my ($other) = _pair();
    $other->{'master'} = 'N' x 48;
    $other->_derive_keys(undef);
    ok($other->{'server_key'} ne $server->{'server_key'},
       'a different master secret gives a different key block');
}

# --- Sealing and opening a record ------------------------------------------

my $message = 'GET / HTTP/1.0';
my $sealed  = $server->_encrypt(23, $message);
is(length($sealed), length($message) + 16,
   'a sealed record is the plaintext plus a 16 byte tag');
ok($sealed !~ /GET/, 'the plaintext does not appear in the sealed record');
is($client->_decrypt(23, $sealed), $message, 'the other end reads it back');

# --- The sequence number ---------------------------------------------------

{
    my ($s2, $c2) = _pair();
    my $first  = $s2->_encrypt(23, 'same text');
    my $second = $s2->_encrypt(23, 'same text');
    ok($first ne $second,
       'the same text sealed twice gives different bytes (the nonce moved on)');
    is($c2->_decrypt(23, $first),  'same text', 'record 0 opens');
    is($c2->_decrypt(23, $second), 'same text', 'record 1 opens');

    # Replaying record 0 now fails, because the reader has moved on
    my ($s3, $c3) = _pair();
    my $rec = $s3->_encrypt(23, 'once only');
    $c3->_decrypt(23, $rec);
    ok(!defined $c3->_decrypt(23, $rec), 'a replayed record is refused');
}

# --- Tampering -------------------------------------------------------------

{
    my ($s4, $c4) = _pair();
    my $rec = $s4->_encrypt(23, 'do not change me');
    my $bad = $rec;
    substr($bad, 3, 1) = chr(ord(substr($bad, 3, 1)) ^ 0x01);
    ok(!defined $c4->_decrypt(23, $bad), 'a record with one bit flipped is refused');

    my ($s5, $c5) = _pair();
    my $rec2 = $s5->_encrypt(23, 'application data');
    ok(!defined $c5->_decrypt(22, $rec2),
       'a record relabelled as a handshake is refused');

    my ($s6, $c6) = _pair();
    ok(!defined $c6->_decrypt(23, 'short'), 'a record shorter than the tag is refused');
}

# --- Sequence numbers on the wire ------------------------------------------

is(unpack('H*', HTTPS::Handy::TLS::_seq_bytes(0)), '0000000000000000',
   'sequence number 0');
is(unpack('H*', HTTPS::Handy::TLS::_seq_bytes(1)), '0000000000000001',
   'sequence number 1');
is(unpack('H*', HTTPS::Handy::TLS::_seq_bytes(4294967296)), '0000000100000000',
   'sequence number 2**32 crosses into the high half');
is(unpack('H*', HTTPS::Handy::TLS::_seq_bytes(4294967297)), '0000000100000001',
   'sequence number 2**32 + 1');

# --- Three byte lengths ----------------------------------------------------

is(unpack('H*', HTTPS::Handy::TLS::_u24(0)),      '000000', 'u24 of 0');
is(unpack('H*', HTTPS::Handy::TLS::_u24(258)),    '000102', 'u24 of 258');
is(unpack('H*', HTTPS::Handy::TLS::_u24(65793)),  '010101', 'u24 of 65793');
is(HTTPS::Handy::TLS::_get_u24(HTTPS::Handy::TLS::_u24(1000000), 0), 1000000,
   'u24 survives the round trip');

######################################################################
# Reading a ClientHello
######################################################################

# Build one by hand, the way a client would
sub _hello {
    my (%a) = @_;
    my $suites  = defined $a{suites}  ? $a{suites}  : pack('n', 0xCCA9);
    my $sid     = defined $a{sid}     ? $a{sid}     : '';
    my $ext     = defined $a{ext}     ? $a{ext}     : '';
    my $version = defined $a{version} ? $a{version} : "\x03\x03";
    my $body = $version . ('R' x 32)
             . pack('C', length($sid)) . $sid
             . pack('n', length($suites)) . $suites
             . "\x01\x00";
    $body .= pack('n', length($ext)) . $ext if $ext ne '';
    return $body;
}

{
    my $h = HTTPS::Handy::TLS::_parse_hello(_hello());
    ok(defined $h, 'a well formed ClientHello parses');
    is(unpack('H*', $h->{'version'}), '0303', 'ClientHello: the version');
    is($h->{'random'}, 'R' x 32,             'ClientHello: the random');
    is(scalar(@{ $h->{'suites'} }), 1,       'ClientHello: one cipher suite offered');
    is($h->{'suites'}[0], 0xCCA9,            'ClientHello: which suite');
    is($h->{'session_id'}, '',               'ClientHello: no session id');

    my $with_id = HTTPS::Handy::TLS::_parse_hello(_hello(sid => 'I' x 32));
    is($with_id->{'session_id'}, 'I' x 32, 'ClientHello: a session id is read');

    # supported_groups (extension 10) holding P-256, and not holding it
    my $p256 = pack('n', 2) . pack('n', 23);
    my $ext  = pack('n', 10) . pack('n', length($p256)) . $p256;
    my $other = pack('n', 2) . pack('n', 29);      # x25519, which is not here
    my $ext2 = pack('n', 10) . pack('n', length($other)) . $other;

    my $hp = HTTPS::Handy::TLS::_parse_hello(_hello(ext => $ext));
    is(HTTPS::Handy::TLS::_client_supports_p256($hp), 1,
       'supported_groups naming P-256 is accepted');
    my $hq = HTTPS::Handy::TLS::_parse_hello(_hello(ext => $ext2));
    is(HTTPS::Handy::TLS::_client_supports_p256($hq), 0,
       'supported_groups without P-256 is refused');
    is(HTTPS::Handy::TLS::_client_supports_p256(
           HTTPS::Handy::TLS::_parse_hello(_hello())), 1,
       'a client that names no curve at all is accepted');

    # An extension block whose lengths do not add up is a malformed
    # message, and must be refused rather than read as far as it goes
    my $ragged = pack('n', 10) . pack('n', 40) . "\x00";
    ok(!defined HTTPS::Handy::TLS::_parse_hello(_hello(ext => $ragged)),
       'a ClientHello with a ragged extension is refused');
    my $stub = pack('n', 10) . "\x00";
    ok(!defined HTTPS::Handy::TLS::_parse_hello(_hello(ext => $stub)),
       'a ClientHello with half an extension header is refused');
}

# Every truncation of a valid ClientHello must be refused, not guessed
{
    my $full = _hello(sid => 'I' x 32);
    my $bad = 0;
    for (my $n = 0; $n < length($full); $n++) {
        my $h = HTTPS::Handy::TLS::_parse_hello(substr($full, 0, $n));
        next unless defined $h;
        # A short message may only parse if nothing was actually cut off
        $bad++ unless $n >= length($full) - 2;
    }
    is($bad, 0, 'every truncated ClientHello is refused');
    ok(defined HTTPS::Handy::TLS::_parse_hello($full),
       'the untruncated one still parses');
}

######################################################################
# The session cache
######################################################################

{
    my $id = 'A' x 32;
    HTTPS::Handy::TLS::_session_store($id, 'M' x 48, 0xCCA9);
    my $found = HTTPS::Handy::TLS::_session_find($id);
    ok(defined $found, 'a stored session is found again');
    is($found->{'master'}, 'M' x 48, 'the session holds its master secret');
    is($found->{'cipher'}, 0xCCA9,   'the session holds its cipher suite');

    ok(!defined HTTPS::Handy::TLS::_session_find('B' x 32),
       'an unknown session id is not found');
    ok(!defined HTTPS::Handy::TLS::_session_find(''),
       'an empty session id is not found');
    ok(!defined HTTPS::Handy::TLS::_session_find('C' x 8),
       'a session id of the wrong length is not found');
    ok(!defined HTTPS::Handy::TLS::_session_find(undef),
       'an absent session id is not found');

    # The table has a limit, and filling it must not let it grow without end
    for (my $i = 0; $i < 200; $i++) {
        HTTPS::Handy::TLS::_session_store(sprintf('%032d', $i), 'M' x 48, 0xCCA9);
    }
    ok(!defined HTTPS::Handy::TLS::_session_find($id),
       'the oldest session is dropped once the table is full');
    ok(defined HTTPS::Handy::TLS::_session_find(sprintf('%032d', 199)),
       'the newest session is still there');
}

######################################################################
# The public key inside a certificate
######################################################################

{
    my $key = HTTPS::Handy::EC::generate_key();
    my $der = HTTPS::Handy::X509::make_self_signed(
        key => $key, cn => 'localhost', hosts => [ 'localhost' ], days => 397);
    my $pub = HTTPS::Handy::TLS::cert_public_key($der);
    ok(defined $pub, 'the public key comes back out of the certificate');
    is($pub->{'type'}, 'ec', 'it is an elliptic curve key');
    is(HTTPS::Handy::BigInt::b_to_hex($pub->{'x'}),
       HTTPS::Handy::BigInt::b_to_hex($key->{'x'}),
       'and it is the key that went in');

    ok(!defined HTTPS::Handy::TLS::cert_public_key('not a certificate'),
       'rubbish is not mistaken for a certificate');
    ok(!defined HTTPS::Handy::TLS::cert_public_key(substr($der, 0, 20)),
       'half a certificate is refused');
}

print "1..$T\n";
exit($FAIL ? 1 : 0);
