#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::cares qw(:status :types);

my @names = @ARGV;
@names = ('google.com', 'cloudflare.com', 'github.com') unless @names;

my $r = EV::cares->new(
    timeout => 5,
    tries   => 3,
);

my $pending = 0;

for my $name (@names) {
    $pending++;
    $r->resolve($name, sub {
        my ($status, @addrs) = @_;
        if ($status == ARES_SUCCESS) {
            printf "%-30s %s\n", $name, join(', ', @addrs);
        } else {
            printf "%-30s ERROR: %s\n", $name, EV::cares::strerror($status);
        }
        EV::break unless --$pending;
    });

    # also query MX
    $pending++;
    $r->search($name, T_MX, sub {
        my ($status, @mx) = @_;
        if ($status == ARES_SUCCESS) {
            for my $rec (@mx) {
                printf "%-30s MX %d %s\n", $name, $rec->{priority}, $rec->{host};
            }
        }
        EV::break unless --$pending;
    });
}

printf "resolving %d names (%d queries)...\n", scalar @names, $pending;
EV::run;
printf "done. c-ares %s\n", EV::cares::lib_version();
