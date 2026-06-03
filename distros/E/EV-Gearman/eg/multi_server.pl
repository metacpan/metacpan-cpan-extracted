#!/usr/bin/env perl
# Round-robin client across multiple gearmand instances with
# per-server health tracking. Useful when you run a small farm of
# gearmand daemons for HA: jobs go to whichever server is up; failed
# servers are skipped until they recover.
#
# Note: foreground submissions stay tied to the server that issued
# the JOB_CREATED — so if that server dies mid-job, you'll see a
# "disconnected" error on the in-flight callback. This script just
# picks a healthy server at submit time.
use strict;
use warnings;
use EV;
use EV::Gearman;

my @servers = qw(127.0.0.1:4730 127.0.0.1:4731 127.0.0.1:4732);
my @clients;
my @healthy;

for my $i (0 .. $#servers) {
    my ($h, $p) = split /:/, $servers[$i];
    $healthy[$i] = 0;
    $clients[$i] = EV::Gearman->new(
        host          => $h,
        port          => $p,
        reconnect     => 1,
        on_connect    => sub { $healthy[$i] = 1; warn "[$i] $servers[$i] up\n"   },
        on_disconnect => sub { $healthy[$i] = 0; warn "[$i] $servers[$i] down\n" },
        on_error      => sub { warn "[$i] $servers[$i]: $_[0]\n"                 },
    );
}

# Round-robin among healthy servers
my $rr = 0;
sub pick_client {
    for (1 .. @clients) {
        my $i = $rr++ % @clients;
        return $clients[$i] if $healthy[$i];
    }
    return undef;
}

sub submit {
    my ($func, $workload, $cb) = @_;
    my $g = pick_client;
    return $cb->(undef, "no healthy gearmand") unless $g;
    $g->submit_job($func, $workload, $cb);
}

# Demo: fire 50 jobs and report
my $remaining = 50;
my @results;
for my $i (1 .. 50) {
    submit(reverse => "msg-$i", sub {
        push @results, [$i, @_];
        $remaining--;
        EV::break if $remaining == 0;
    });
}

my $t = EV::timer 10, 0, sub { warn "timeout\n"; EV::break };
EV::run;

my $ok = grep { !defined $_->[2] } @results;
warn "submitted: $ok ok / ", scalar(@results), " total\n";
