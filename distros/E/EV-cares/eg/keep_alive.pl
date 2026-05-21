#!/usr/bin/env perl
# Long-running daemon pattern: a single EV::cares instance refreshes a
# fixed set of names every $interval seconds, handling transient upstream
# failures by calling reinit() (which re-reads /etc/resolv.conf) and
# logging fail-over behavior.  Intended as a copyable starting point for
# health-check daemons that need cached, periodically-refreshed records.
#
# Usage:
#   perl eg/keep_alive.pl                  # default 30s, defaults to a few hosts
#   perl eg/keep_alive.pl 5 cloudflare.com github.com
#   ^C to stop
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my $interval = (@ARGV && $ARGV[0] =~ /^\d+\z/) ? shift : 30;
my @names    = @ARGV ? @ARGV : qw(cloudflare.com github.com perl.org);

my %TRANSIENT = map { $_ => 1 }
    ARES_ETIMEOUT, ARES_ESERVFAIL, ARES_ECONNREFUSED, ARES_ENOTINITIALIZED;

my $r = EV::cares->new(timeout => 5, tries => 2);
my %cache;       # name => { addrs, status, fetched }
my $consec_fail = 0;

my $tick = sub {
    my $when = scalar localtime;
    print "[$when] refresh ", scalar(@names), " names\n";
    $r->resolve_all(\@names, sub {
        my $results = shift;
        my $failures = 0;
        for my $name (sort keys %$results) {
            my $st     = $results->{$name}{status};
            my @addrs  = @{ $results->{$name}{addrs} || [] };
            $cache{$name} = {
                status  => $st,
                addrs   => \@addrs,
                fetched => time,
            };
            if ($st == ARES_SUCCESS) {
                printf "  %-25s %s\n", $name, join(', ', @addrs);
            } else {
                printf "  %-25s ERR %s\n", $name,
                    EV::cares::strerror($st);
                $failures++ if $TRANSIENT{$st};
            }
        }

        # Conservative reinit policy: only escalate to a resolv.conf re-read
        # when *every* tracked name transient-failed for 3 consecutive ticks.
        # A copyable variant for noisier environments might instead trip on
        # `$failures > 0` (any transient failure) or `$failures / @names >=
        # 0.5` (majority failure).
        if ($failures && $failures == scalar @names) {
            $consec_fail++;
            warn "[$when] all names transient-failed; consec=$consec_fail\n";
            if ($consec_fail >= 3) {
                warn "[$when] reinit() to re-read system resolvers\n";
                eval { $r->reinit };
                $consec_fail = 0;
            }
        } else {
            $consec_fail = 0;
        }
    });
};

# fire once at startup, then every $interval seconds
$tick->();
my $w = EV::timer $interval, $interval, $tick;

# allow Ctrl-C to break out of EV::run cleanly
my $sig = EV::signal 'INT', sub {
    print "\n[signal] INT -- exiting\n";
    EV::break;
};

EV::run;

print "Final cache:\n";
for my $name (sort keys %cache) {
    printf "  %-25s status=%d addrs=%d age=%ds\n",
        $name, $cache{$name}{status},
        scalar @{$cache{$name}{addrs}},
        time - $cache{$name}{fetched};
}
