#!/usr/bin/env perl
# SRV record lookup for service discovery
# Usage: perl eg/srv.pl _imaps._tcp.gmail.com
#        perl eg/srv.pl _http._tcp.example.com
use strict;
use warnings;
use EV;
use EV::cares qw(:status :types);

my $name = shift || '_imaps._tcp.gmail.com';
my $r = EV::cares->new(timeout => 5);

$r->search($name, T_SRV, sub {
    my ($status, @srv) = @_;
    if ($status != ARES_SUCCESS) {
        die "SRV lookup failed: " . EV::cares::strerror($status) . "\n";
    }

    printf "SRV records for %s:\n", $name;
    for my $rec (sort { $a->{priority} <=> $b->{priority}
                     || $b->{weight}   <=> $a->{weight} } @srv) {
        printf "  priority=%d weight=%d %s:%d\n",
            $rec->{priority}, $rec->{weight}, $rec->{target}, $rec->{port};
    }
    EV::break;
});

EV::run;
