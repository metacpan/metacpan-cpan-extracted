# Malformed server responses must surface as a clean connection-level
# error, not a crash or hang. A fake server sends garbage; we assert
# on_error reports the right reason. No gearmand needed.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

# Spin a one-shot server that, as soon as a client connects, writes
# $bad_bytes and holds the socket open. Returns the error string the
# client's on_error reported (or undef on timeout).
sub provoke {
    my ($bad_bytes) = @_;
    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
    ) or plan skip_all => "cannot bind listener: $!";
    my $port = $srv->sockport;
    $srv->blocking(0);

    my @conns;
    my $accept_w = EV::io fileno($srv), EV::READ, sub {
        my $c = $srv->accept or return;
        $c->blocking(0);
        push @conns, $c;             # keep open
        syswrite $c, $bad_bytes;
    };

    my $err;
    my $g = EV::Gearman->new(
        host => '127.0.0.1', port => $port,
        on_error => sub { $err //= $_[0]; EV::break },
    );
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    undef $g;
    close $_ for @conns;
    close $srv;
    return $err;
}

# 1) First byte is NUL (binary path) but the 4-byte magic is not "\0RES".
my $bad_magic = "\0BAD" . ("\0" x 8);          # 12-byte header, wrong magic
is provoke($bad_magic), 'invalid response magic',
    'wrong response magic disconnects with "invalid response magic"';

# 2) Valid magic but an absurd body length (> GM_MAX_PACKET = 256 MiB).
my $too_big = "\0RES" . pack('N', 17) . pack('N', 0xFFFFFFFF);
is provoke($too_big), 'response packet too large',
    'oversized declared length disconnects with "response packet too large"';

# 3) Printable bytes with no admin request outstanding: the text
#    parser finds the queue head is not a CB_ADMIN entry.
is provoke("garbage line\n"),
    'unexpected admin response (queue head is not admin)',
    'stray text reply disconnects with "unexpected admin response"';

# 4) Orderly server close (FIN) after the connection is up -> EOF.
{
    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
    ) or plan skip_all => "cannot bind listener: $!";
    my $port = $srv->sockport;
    $srv->blocking(0);
    my $accept_w = EV::io fileno($srv), EV::READ, sub {
        my $c = $srv->accept or return;
        close $c;                    # accept completes the handshake, then FIN
    };
    my $err;
    my $g = EV::Gearman->new(
        host => '127.0.0.1', port => $port,
        on_error => sub { $err //= $_[0]; EV::break },
    );
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    undef $g; close $srv;
    is $err, 'connection closed by server',
        'server EOF reports "connection closed by server"';
}

done_testing;
