#!/usr/bin/env perl
# Probe a list of upstream resolvers and report whether they claim to have
# DNSSEC-validated a given name (AD bit set in the response header).
#
# The AD bit indicates that the *upstream* resolver validated the chain —
# not that we did.  Treat this as a "is this resolver bothering to verify?"
# signal, not as cryptographic proof.
#
# Usage:
#   perl eg/upstream_ad_check.pl cloudflare.com
#   perl eg/upstream_ad_check.pl @9.9.9.9 @1.1.1.1 example.com
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my @servers;
while (@ARGV && $ARGV[0] =~ /^\@(.+)/) { push @servers, $1; shift }
@servers = ('1.1.1.1', '8.8.8.8', '9.9.9.9') unless @servers;
my $name = shift // 'cloudflare.com';

# Need the EDNS flag so the upstream actually sets DO and reports AD;
# without it many resolvers strip the AD bit out of paranoia.
my $flags = ARES_FLAG_EDNS;

printf "Querying %s for an A record on %d resolver(s)\n\n", $name, scalar @servers;
printf "%-20s %-7s %-7s %-7s %s\n", 'server', 'rcode', 'ad', 'ra', 'note';
printf "%s\n", '-' x 60;

my $pending = scalar @servers;
my @resolvers;   # keep resolvers alive across the for loop iterations;
                 # otherwise each $r drops to refcount 0 at end-of-iter,
                 # DESTROY runs ares_destroy, and every callback fires
                 # with ARES_EDESTRUCTION before we ever pump EV::run.
for my $srv (@servers) {
    my $r = EV::cares->new(servers => [$srv], flags => $flags, timeout => 5);
    push @resolvers, $r;
    $r->query($name, C_IN, T_A, sub {
        my ($status, $buf) = @_;
        my $note = '';
        my ($rcode, $ad, $ra) = ('-', '-', '-');
        if ($status == ARES_SUCCESS && defined $buf && length $buf >= 12) {
            my $h = EV::cares::parse_header($buf);
            $rcode = rcode_name($h->{rcode});
            $ad    = $h->{ad} ? 'set'    : 'clear';
            $ra    = $h->{ra} ? 'set'    : 'clear';
            $note  = 'truncated, retry over TCP' if $h->{tc};
        } else {
            $note = EV::cares::strerror($status);
        }
        printf "%-20s %-7s %-7s %-7s %s\n", $srv, $rcode, $ad, $ra, $note;
        EV::break unless --$pending;
    });
}
EV::run;

sub rcode_name {
    my %m = (0 => 'NOERROR', 1 => 'FORMERR', 2 => 'SERVFAIL',
             3 => 'NXDOMAIN', 4 => 'NOTIMP',  5 => 'REFUSED');
    $m{$_[0]} // sprintf 'RCODE(%d)', $_[0];
}
