#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use IO::Select;
use Time::HiRes ();
use Hyperman;

# Address validation and the things a server owes a client it
# cannot place.
#
# A QUIC server sends its whole first flight - certificate included - to an
# address it has not heard back from, so a spoofed source turns it into an
# amplifier. Retry and NEW_TOKEN are the answer, and a Stateless Reset is what
# a client gets when it addresses a connection that no longer exists.

plan skip_all => 'HTTP/3 support not built' unless Hyperman->has_http3;

# ---- the tokens themselves ------------------------------------------------
#
# This drives the library the same way the receive path does and asserts the
# property the receive path depends on. It is NOT a test of hm_quic_packet's
# call sites - it is a test of the assumption those call sites are built on,
# which is the half that would otherwise be believed rather than checked.

is(Hyperman::_quic_token_selftest(), 1,
   'a token verifies for the address, connection id and secret it was minted '
 . 'for, and fails for any other, when tampered, and when expired');

# ---- a stateless reset for a connection that is gone ----------------------

my $openssl = `which openssl 2>/dev/null`;
chomp $openssl;
plan skip_all => 'no openssl to make a test certificate' unless $openssl;

my $dir = "hm_h3tok_$$";
mkdir $dir or plan skip_all => "cannot make $dir";
my ($cert, $key) = ("$dir/c.pem", "$dir/k.pem");
if (system(qq{$openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert }
         . qq{-days 1 -nodes -subj "/CN=localhost" >/dev/null 2>&1}) != 0) {
    unlink $cert, $key; rmdir $dir;
    plan skip_all => 'openssl could not make a test certificate';
}

my ($port) = free_ports(1);
unless ($port) {
    unlink $cert, $key; rmdir $dir;
    plan skip_all => 'no free loopback port';
}

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    quiet_child();
    require Hyperman;
    Hyperman->run(
        app => sub {
            my $env = shift;
            if ($env->{PATH_INFO} eq '/stats') {
                my $s = Hyperman->stats;
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ "h3_conns=$s->{h3_conns} h3_live=$s->{h3_live} "
                         . "datagrams=$s->{datagrams}" ] ];
            }
            [ 404, [ 'Content-Type' => 'text/plain' ], ['nope'] ];
        },
        host            => '127.0.0.1',
        port            => $port,
        workers         => 1,
        http3           => 1,
        http3_max_conns => 64,
        tls_cert        => $cert,
        tls_key         => $key,
    );
    exit 0;
}

sub stats {
    my $req = "GET /stats HTTP/1.1\r\nHost: 127.0.0.1\r\n"
            . "Connection: close\r\n\r\n";
    open my $fh, '-|', qq{printf '%s' '$req' | $openssl s_client -quiet }
                     . qq{-connect 127.0.0.1:$port 2>/dev/null} or return {};
    local $/;
    my $r = <$fh>;
    close $fh;
    return { ($r || '') =~ /(\w+)=(\d+)/g };
}

my $up = {};
for (1 .. 100) {
    $up = stats();
    last if exists $up->{h3_conns};
    Time::HiRes::sleep(0.05);
}
ok(exists $up->{h3_conns}, 'the listener started with http3_max_conns set')
    or diag 'server never came up';

SKIP: {
    skip 'server did not start', 3 unless exists $up->{h3_conns};

    my $u = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                  Proto => 'udp');
    ok($u, 'a UDP socket to the QUIC listener') or skip 'no udp socket', 2;

    # A short header naming a Connection ID this server has never issued.
    # That is what a client sends to a server that has restarted: without an
    # answer it retries until its idle timeout, so the server owes it a
    # Stateless Reset. Padded past the size below which answering would not
    # be worth it.
    my $unknown = join('', map { chr(($_ * 7 + 3) % 256) } 1 .. 16);
    my $probe   = "\x40" . $unknown . ("\x00" x 64);
    cmp_ok(length $probe, '>=', 41, 'the probe is big enough to deserve a reply');
    $u->send($probe);

    my $sel = IO::Select->new($u);
    my $reply = '';
    if ($sel->can_read(3)) { $u->recv($reply, 2048); }

    ok(length $reply,
       'an unknown connection id gets a Stateless Reset rather than silence');

    # The reply must be SMALLER than what arrived. This path answers an
    # unauthenticated packet from an unverified address, so if it could ever
    # be larger it would be an amplifier - which is the exact thing address
    # validation exists to prevent.
    cmp_ok(length $reply, '<', length $probe,
           'and the reset is smaller than the packet that provoked it, so '
         . 'this path can never amplify')
        if length $reply;

    close $u;
}

kill 'TERM', $pid;
server_reap($pid);
unlink $cert, $key;
rmdir $dir;
done_testing();
