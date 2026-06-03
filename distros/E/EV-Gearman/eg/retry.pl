#!/usr/bin/env perl
# Client-side retry with exponential backoff.
#
# Re-submits a foreground job up to N times when it fails or the
# connection drops. Use sparingly — most production systems prefer
# server-side retries (gearmand --job-retries) plus idempotent
# workers, but client-side retries are useful for transient errors
# during deployments / failovers.
use strict;
use warnings;
use EV;
use EV::Gearman;

my $g = EV::Gearman->new(
    host      => '127.0.0.1',
    port      => 4730,
    reconnect => 1,
);

sub submit_with_retry {
    my ($func, $workload, %opts) = @_;
    my $max_attempts = $opts{max_attempts}  // 3;
    my $base_delay   = $opts{base_delay_ms} // 100;
    my $cb           = $opts{cb};

    my $attempt = 0;
    my $try; $try = sub {
        $attempt++;
        $g->submit_job($func, $workload, sub {
            my ($result, $err) = @_;
            if (!$err) {
                undef $try;
                $cb->($result, undef, $attempt);
                return;
            }
            if ($attempt >= $max_attempts) {
                undef $try;
                $cb->(undef, "giving up after $attempt attempts: $err",
                      $attempt);
                return;
            }
            my $delay = ($base_delay * (2 ** ($attempt - 1))) / 1000;
            warn "[retry] attempt $attempt failed ($err); sleeping ${delay}s\n";
            # Retain the timer: a bare EV::timer in void context is freed
            # when this callback returns, so the retry would never fire.
            my $t; $t = EV::timer $delay, 0, sub { undef $t; $try->() };
        });
    };
    $try->();
}

# Demo: a worker that always dies, so every attempt comes back as
# "job failed" and the retries are actually exercised. (Submitting to a
# function nobody serves would NOT fail — gearmand just queues it.)
my $func = 'flaky_'.$$;
my $wkr = EV::Gearman->new(host => '127.0.0.1', port => 4730);
$wkr->register_function($func => sub { die "boom\n" });
$wkr->work;

submit_with_retry(
    $func, "x",
    max_attempts  => 3,
    base_delay_ms => 100,
    cb            => sub {
        my ($r, $e, $tries) = @_;
        warn "final: result=", ($r // "undef"),
             " err=", ($e // "undef"),
             " (tried $tries times)\n";
        EV::break;
    },
);

# Wait long enough for the retries
my $w = EV::timer 5, 0, sub { EV::break };
EV::run;
