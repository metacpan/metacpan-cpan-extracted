#!/usr/bin/env perl
# Benchmark: EV::cares concurrent vs sequential blocking getaddrinfo
# Shows the concurrency advantage for many distinct lookups.
# Usage: perl eg/bench.pl [count]
use strict;
use warnings;
use EV;
use EV::cares qw(:status);
use Socket qw(getaddrinfo AF_INET SOCK_STREAM);
use Time::HiRes ();

my $count = shift || 20;

# distinct domains to avoid resolver cache effects
my @domains = qw(
    google.com amazon.com facebook.com cloudflare.com github.com
    stackoverflow.com wikipedia.org reddit.com netflix.com apple.com
    microsoft.com twitter.com linkedin.com instagram.com yahoo.com
    bing.com duckduckgo.com whatsapp.com telegram.org signal.org
    mozilla.org kernel.org debian.org ubuntu.com archlinux.org
    rust-lang.org golang.org python.org perl.org cpan.org
);
splice @domains, $count if @domains > $count;
$count = scalar @domains;

printf "resolving %d distinct domains\n\n", $count;

# --- sequential blocking getaddrinfo ---
{
    my ($ok, $fail) = (0, 0);
    my $t0 = Time::HiRes::time();

    for my $name (@domains) {
        my ($err, @res) = getaddrinfo($name, '80', { family => AF_INET, socktype => SOCK_STREAM });
        if ($err) { $fail++ } else { $ok++ }
    }

    my $elapsed = Time::HiRes::time() - $t0;
    printf "sequential getaddrinfo: %d ok, %d fail, %6.3fs  (%4.0f q/s)\n",
        $ok, $fail, $elapsed, $count / ($elapsed || 1);
}

# --- EV::cares concurrent ---
{
    my $r = EV::cares->new(timeout => 5, tries => 2);
    my ($ok, $fail, $pending) = (0, 0, 0);
    my $t0 = Time::HiRes::time();

    for my $name (@domains) {
        $pending++;
        $r->resolve($name, sub {
            if ($_[0] == ARES_SUCCESS) { $ok++ } else { $fail++ }
            EV::break unless --$pending;
        });
    }

    EV::run;

    my $elapsed = Time::HiRes::time() - $t0;
    printf "EV::cares concurrent  : %d ok, %d fail, %6.3fs  (%4.0f q/s)\n",
        $ok, $fail, $elapsed, $count / ($elapsed || 1);
}

print "\nnote: getaddrinfo uses system resolver (nscd/systemd-resolved cache),\n";
print "      c-ares queries DNS servers directly. concurrency advantage grows\n";
print "      with query count and network latency.\n";
