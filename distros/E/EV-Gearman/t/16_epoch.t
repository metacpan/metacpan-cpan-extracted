# SUBMIT_JOB_EPOCH wire encoding. Whether gearmand executes an epoch
# job is the server's business (its default builtin queue accepts but
# never runs them); what THIS module guarantees is the packet it emits.
# A fake server decodes the request and asserts the body is exactly
# FUNC\0UNIQUE\0EPOCH\0WORKLOAD, with the EPOCH field rendered as the
# decimal integer passed in — including a value past 2^31, to catch
# signed/32-bit truncation. The old test hardcoded nothing but also
# asserted nothing about the wire, so an epoch hardcoded to "0" in the
# XS left it green; this one goes red. No gearmand needed.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

use constant {
    GM_CMD_SUBMIT_JOB_EPOCH => 36,
    GM_CMD_JOB_CREATED      => 8,
};

# Spin a one-shot capture server, connect a client, run $submit->($cli,
# $cb) once connected, and return ([captured packets], @cb_args).
# Each captured packet is [magic, cmd, declared_len, body].
sub submit_and_capture {
    my ($submit) = @_;

    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
    ) or plan skip_all => "cannot bind listener: $!";
    $srv->blocking(0);
    my $port = $srv->sockport;

    my @pkts;
    my @cb_args;
    my ($conn, $read_w);
    my $rbuf = '';
    my $accept_w = EV::io fileno($srv), EV::READ, sub {
        $conn = $srv->accept or return;
        $conn->blocking(0);
        $read_w = EV::io fileno($conn), EV::READ, sub {
            my $n = sysread($conn, my $chunk, 65536);
            if (!$n) { undef $read_w; return; }
            $rbuf .= $chunk;
            while (length($rbuf) >= 12) {
                my ($magic, $cmd, $len) = unpack "a4 N N", $rbuf;
                last if length($rbuf) < 12 + $len;
                my $body = substr($rbuf, 12, $len);
                substr($rbuf, 0, 12 + $len) = '';
                push @pkts, [$magic, $cmd, $len, $body];
                if ($cmd == GM_CMD_SUBMIT_JOB_EPOCH) {
                    my $handle = "H:fake:$$";
                    syswrite $conn, "\0RES"
                        . pack("N N", GM_CMD_JOB_CREATED, length $handle)
                        . $handle;
                }
            }
        };
    };

    my $cli;
    $cli = EV::Gearman->new(
        host => '127.0.0.1', port => $port,
        on_connect => sub {
            $submit->($cli, sub { @cb_args = @_; EV::break });
        },
    );
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;

    undef $cli; undef $read_w; undef $accept_w;
    close $conn if $conn;
    close $srv;
    return (\@pkts, \@cb_args);
}

my $func = "epoch_wire_$$";

# --- 1. epoch with explicit unique -----------------------------------
{
    my $epoch = 1735689600;   # 2025-01-01T00:00:00Z
    my ($pkts, $cb) = submit_and_capture(sub {
        my ($cli, $cb) = @_;
        $cli->submit_job_epoch($func, 'payload', $epoch,
            { unique => 'u-key' }, $cb);
    });

    is scalar(@$pkts), 1, 'client sent exactly one packet';
    my ($magic, $cmd, $len, $body) = @{ $pkts->[0] };
    is $magic, "\0REQ", 'request magic is \0REQ';
    is $cmd, GM_CMD_SUBMIT_JOB_EPOCH, 'command is SUBMIT_JOB_EPOCH (36)';
    is $len, length($body), 'declared length matches body length';
    is $body, "$func\0u-key\0$epoch\0payload",
        'body is exactly FUNC\0UNIQUE\0EPOCH\0WORKLOAD';
    is_deeply $cb, ["H:fake:$$", undef],
        'JOB_CREATED handle reached the submit callback';
}

# --- 2. epoch past 2^31, no unique ------------------------------------
{
    my $epoch = 4102444800;   # 2100-01-01T00:00:00Z, > 2**31
    my ($pkts, $cb) = submit_and_capture(sub {
        my ($cli, $cb) = @_;
        $cli->submit_job_epoch($func, 'wl2', $epoch, $cb);
    });

    is scalar(@$pkts), 1, 'client sent exactly one packet';
    my ($magic, $cmd, $len, $body) = @{ $pkts->[0] };
    is $cmd, GM_CMD_SUBMIT_JOB_EPOCH, 'command is SUBMIT_JOB_EPOCH (36)';
    is $len, length($body), 'declared length matches body length';
    is $body, "$func\0\0$epoch\0wl2",
        'large epoch survives untruncated; unique field empty when omitted';
    like $cb->[0], qr/\S/, 'JOB_CREATED handle reached the submit callback';
    is $cb->[1], undef, 'no error';
}

done_testing;
