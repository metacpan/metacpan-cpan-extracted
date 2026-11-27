#!/usr/bin/env perl
# JetStream durable pull-consumer worker with explicit ack.
#
# Connects, ensures stream + durable consumer exist, then loops:
#   fetch a batch -> process each msg -> +ACK on success, -NAK on
#   failure (server will redeliver after ack_wait), +WPI for
#   "in progress" if processing takes a while.
#
# Env: NATS_HOST, NATS_PORT, JS_STREAM, JS_SUBJECT, JS_CONSUMER, BATCH.

use strict;
use warnings;
use EV;
use EV::Nats;
use EV::Nats::JetStream;

my $stream    = $ENV{JS_STREAM}   // 'WORK';
my $subject   = $ENV{JS_SUBJECT}  // 'work.>';
my $consumer  = $ENV{JS_CONSUMER} // 'worker';
my $batch     = $ENV{BATCH}       // 8;

my $nats = EV::Nats->new(
    host       => $ENV{NATS_HOST} // '127.0.0.1',
    port       => $ENV{NATS_PORT} // 4222,
    on_error   => sub { warn "nats: $_[0]\n" },
);
my $js = EV::Nats::JetStream->new(nats => $nats);

$js->stream_create({ name => $stream, subjects => [ $subject ] }, sub {
    my (undef, $err) = @_;
    warn "stream_create: $err\n" if $err && $err !~ /already in use|already exists/i;

    $js->consumer_create($stream, {
        durable_name => $consumer,
        ack_policy   => 'explicit',
        ack_wait     => 30 * 1_000_000_000,   # 30s
        max_ack_pending => $batch * 4,
    }, sub {
        my (undef, $err) = @_;
        warn "consumer_create: $err\n" if $err && $err !~ /already exists|already in use/i;

        warn "[worker] fetching from $stream/$consumer batch=$batch\n";
        loop_fetch();
    });
});

sub loop_fetch {
    $js->fetch($stream, $consumer, { batch => $batch, expires => 5_000_000_000 }, sub {
        my ($msgs, $err) = @_;
        if ($err) {
            warn "[worker] fetch error: $err - retrying in 1s\n";
            my $rt; $rt = EV::timer(1, 0, sub { undef $rt; loop_fetch() });
            return;
        }
        process($_) for @$msgs;
        loop_fetch();
    });
}

sub process {
    my ($msg) = @_;

    # in_progress keeps the server from redelivering a long task
    my $progress = EV::timer(10, 10, sub { $js->in_progress($msg) });

    my $ok = eval {
        # ... your work here ...
        warn "[worker] $msg->{subject}: " . substr($msg->{payload} // '', 0, 60) . "\n";
        die "demo: payload says 'fail'\n" if ($msg->{payload} // '') =~ /\bfail\b/;
        1;
    };
    undef $progress;

    return $js->ack($msg) if $ok;
    warn "[worker] -> nak ($@)";
    $js->nak($msg);
}

EV::run;
