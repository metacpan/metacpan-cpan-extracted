#!/usr/bin/env perl
# DNS health check: resolve a set of hosts and report status
# Usage: perl eg/healthcheck.pl [host1 host2 ...]
use strict;
use warnings;
use EV;
use EV::cares qw(:status);
use Time::HiRes ();

my @hosts = @ARGV;
@hosts = qw(
    google.com
    cloudflare.com
    github.com
    amazon.com
    invalid.example.test
) unless @hosts;

my $r = EV::cares->new(timeout => 3, tries => 2);
my $pending = 0;
my @results;

for my $host (@hosts) {
    $pending++;
    my $t0 = Time::HiRes::time();

    $r->resolve($host, sub {
        my ($status, @addrs) = @_;
        my $elapsed = (Time::HiRes::time() - $t0) * 1000;

        push @results, {
            host    => $host,
            status  => $status,
            addrs   => [@addrs],
            time_ms => $elapsed,
        };

        EV::break unless --$pending;
    });
}

EV::run;

# report
printf "%-30s %-8s %-10s %s\n", 'HOST', 'STATUS', 'TIME', 'RESULT';
printf "%s\n", '-' x 75;

my ($ok, $fail) = (0, 0);
for my $r (sort { $a->{host} cmp $b->{host} } @results) {
    if ($r->{status} == ARES_SUCCESS) {
        printf "%-30s %-8s %6.1fms   %s\n",
            $r->{host}, 'OK', $r->{time_ms},
            join(', ', @{$r->{addrs}});
        $ok++;
    } else {
        printf "%-30s %-8s %6.1fms   %s\n",
            $r->{host}, 'FAIL', $r->{time_ms},
            EV::cares::strerror($r->{status});
        $fail++;
    }
}

printf "%s\n", '-' x 75;
printf "%d ok, %d failed\n", $ok, $fail;
exit($fail ? 1 : 0);
