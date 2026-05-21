#!/usr/bin/env perl
# Stream replay: walk a JetStream stream from a given start sequence
# (or start time) and print each message's subject + payload. Useful
# for debugging, audit trails, or rebuilding state from events.
#
#   perl replay.pl <stream> [<filter_subject>] [<start_seq>]
#
# Env: NATS_HOST, NATS_PORT.

use strict;
use warnings;
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use MIME::Base64 qw(decode_base64);

my $stream = shift @ARGV // die "usage: replay.pl <stream> [<subject>] [<start_seq>]\n";
my $filter = shift @ARGV;            # optional subject filter (e.g. "orders.*")
my $start  = shift @ARGV // 1;       # default: from sequence 1

my $nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { die "nats: $_[0]\n" },
);
my $js = EV::Nats::JetStream->new(nats => $nats);

my $seq = $start;
my $count = 0;
fetch_next();
EV::run;

sub fetch_next {
    my %req = $filter
        ? ( next_by_subj => $filter, seq => $seq )
        : ( seq => $seq );
    $js->stream_msg_get($stream, \%req, sub {
        my ($resp, $err) = @_;
        if ($err) {
            if ($err =~ /no message found|10037/) {
                warn "[replay] done at seq=$seq, $count message(s) emitted\n";
            } else {
                warn "[replay] error: $err\n";
            }
            $nats->disconnect; EV::break;
            return;
        }
        my $msg = $resp->{message};
        my $data = decode_base64($msg->{data} || '');
        printf "%-6s %-40s %s\n", $msg->{seq}, $msg->{subject}, $data;
        $count++;
        $seq = $msg->{seq} + 1;
        fetch_next();
    });
}
