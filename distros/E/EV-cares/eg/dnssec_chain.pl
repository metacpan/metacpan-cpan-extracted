#!/usr/bin/env perl
# Walk the DNSSEC trust chain for a zone.
#
# For each label boundary up to the apex, fetch:
#   - the parent zone's DS records (the hash of the child's KSK)
#   - the child zone's DNSKEY records
# Then check whether any DS key_tag matches a DNSKEY key_tag (a SEP-flagged
# key with bit 7 set in flags is a Key-Signing Key).  Cryptographic
# verification of the signature would require RSA/ECDSA primitives — out
# of scope for this minimalistic example.
#
# Usage:
#   perl eg/dnssec_chain.pl example.com
#   perl eg/dnssec_chain.pl @1.1.1.1 example.com
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my @servers;
while (@ARGV && $ARGV[0] =~ /^\@(.+)/) { push @servers, $1; shift }
my $name = shift // 'cloudflare.com';

my $r = EV::cares->new(@servers ? (servers => \@servers) : (), timeout => 5);

# build label suffixes (parent of each cut), skipping the bare TLD because
# a TLD's signing material is identical to what we already get at the
# next-deeper zone: a.b.c -> ('a.b.c', 'b.c', '.').
my @labels = split /\./, $name;
my @zones;
for my $i (0 .. $#labels - 1) {
    push @zones, join '.', @labels[$i .. $#labels];
}
push @zones, '.';   # root

print "Walking DNSSEC trust chain for $name:\n\n";

# Named-sub recursion (rather than a self-referential closure) avoids the
# CV-to-pad reference cycle that perl's refcounter cannot collect.  Same
# pattern as eg/resolver_pool.pl and eg/cache_demo.pl.
walk_zone(0);
EV::run;

sub walk_zone {
    my ($idx) = @_;
    return EV::break if $idx > $#zones;
    my $zone = $zones[$idx];

    my %got;
    my $pending = 2;
    my $continue = sub {
        return if --$pending;
        report($zone, \%got);
        walk_zone($idx + 1);
    };

    $r->search($zone, T_DS, sub {
        my ($status, @recs) = @_;
        $got{ds} = { status => $status, records => \@recs };
        $continue->();
    });
    $r->search($zone, T_DNSKEY, sub {
        my ($status, @recs) = @_;
        $got{dnskey} = { status => $status, records => \@recs };
        $continue->();
    });
}

sub report {
    my ($zone, $got) = @_;
    print "=== $zone ===\n";

    my $ds = $got->{ds};
    if ($ds->{status} == ARES_SUCCESS) {
        for my $r (@{$ds->{records}}) {
            next unless ref $r eq 'HASH';
            printf "  DS:      key_tag=%-6d alg=%-3d digest_type=%d %s\n",
                $r->{key_tag}, $r->{algorithm}, $r->{digest_type},
                substr(unpack('H*', $r->{digest}), 0, 32) . '...';
        }
    } else {
        print "  DS:      ", EV::cares::strerror($ds->{status}), "\n";
    }

    my $dk = $got->{dnskey};
    if ($dk->{status} == ARES_SUCCESS) {
        for my $r (@{$dk->{records}}) {
            next unless ref $r eq 'HASH';
            my $sep = ($r->{flags} & 0x0001) ? 'SEP' : '   ';
            printf "  DNSKEY:  flags=%-5d alg=%-3d %s %d bytes\n",
                $r->{flags}, $r->{algorithm}, $sep, length($r->{public_key});
        }
        # match: any DS key_tag matching a DNSKEY key_tag would need
        # computing the DNSKEY tag per RFC 4034 appendix B, which c-ares
        # does not expose.  Print the count summary instead.
        my @keys = grep { ref } @{$dk->{records}};
        my $ksk_count = grep { $_->{flags} & 0x0001 } @keys;
        printf "  -> %d DNSKEY (%d KSK)\n", scalar @keys, $ksk_count;
    } else {
        print "  DNSKEY:  ", EV::cares::strerror($dk->{status}), "\n";
    }
    print "\n";
}
