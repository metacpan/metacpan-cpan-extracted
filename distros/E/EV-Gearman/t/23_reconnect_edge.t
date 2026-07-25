# Reconnect edge cases. No gearmand needed: a fake server hangs up on
# the first connection and answers on the second.
#
#  1. Re-queueing work from inside on_disconnect is the documented
#     purpose of the wait queue, but the reconnect used to be armed
#     only AFTER on_disconnect/on_error fired, so methods called from
#     those callbacks croaked "not connected". The reconnect must be
#     scheduled first.
#  2. Unix-socket connect failures (path too long, socket(), fcntl)
#     used to bypass report_connect_error and skip reconnect
#     scheduling entirely.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

# --- submit from inside on_disconnect must queue, not croak ---
{
    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 5, ReuseAddr => 1,
    ) or plan skip_all => "cannot bind listener: $!";
    my $port = $srv->sockport;
    $srv->blocking(0);

    my $nconn = 0;
    my $accept_w = EV::io fileno($srv), EV::READ, sub {
        my $c = $srv->accept or return;
        $c->blocking(0);
        $nconn++;
        if ($nconn == 1) {
            # Let the client finish connecting, then hang up.
            my $t;
            $t = EV::timer 0.05, 0, sub { close $c; undef $t };
        } else {
            # Reconnected: answer the ECHO_REQ with an ECHO_RES.
            my $buf = '';
            my $rw;
            $rw = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 4096);
                unless ($n) { close $c; undef $rw; return; }
                $buf .= $chunk;
                return if length($buf) < 12;
                my (undef, $blen) = unpack 'x4NN', $buf;
                return if length($buf) < 12 + $blen;
                my $body = substr $buf, 12, $blen;
                syswrite $c, "\0RES" . pack('NN', 17, length $body) . $body;
            };
        }
    };

    my @warns;
    my ($r, $e, $wc);
    {
        local $SIG{__WARN__} = sub { push @warns, @_ };
        my $g;
        $g = EV::Gearman->new(
            host => '127.0.0.1', port => $port,
            reconnect       => 1,
            reconnect_delay => 50,
            on_error      => sub { },   # expected: "connection closed by server"
            on_disconnect => sub {
                $g->echo('requeue', sub { ($r, $e) = @_; EV::break });
                $wc = $g->waiting_count;
            },
        );
        my $guard = EV::timer 5, 0, sub { fail 'requeue timeout'; EV::break };
        EV::run;
    }

    is $e, undef, 'no error';
    is $r, 'requeue', 'echo queued from on_disconnect completed after reconnect';
    is $wc, 1, 'submit from on_disconnect queued (waiting_count=1)';
    ok !(grep { /not connected/ } @warns),
        'no "not connected" croak from on_disconnect';
}

# --- unix-socket connect failure retries when reconnect is on ---
{
    my $errs = 0;
    my $g = EV::Gearman->new(
        path => '/tmp/' . ('x' x 200),   # far beyond sun_path
        reconnect       => 1,
        reconnect_delay => 30,
        on_error => sub { $errs++; EV::break if $errs >= 2 },
    );
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;
    cmp_ok $errs, '>=', 2, 'unix path-too-long failure retries with reconnect on';
}

done_testing;
