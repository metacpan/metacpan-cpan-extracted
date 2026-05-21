#!/usr/bin/env perl
# Walk the NS chain from the TLD down to the target, plus DNSSEC
# (DS / DNSKEY) summary at each level.  Uses the system resolver, so
# this is "show me the delegation chain" rather than a full
# iterative +trace from the root (which requires raw queries and
# AUTHORITY-section parsing — out of scope for an example).
# Usage: perl eg/zone_trace.pl example.com [type=A]
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my $target = shift or die "usage: $0 NAME [TYPE]\n";
my $type   = uc(shift // 'A');
my %types  = (A => T_A, AAAA => T_AAAA, MX => T_MX, NS => T_NS,
              TXT => T_TXT, SOA => T_SOA, CAA => T_CAA, HTTPS => T_HTTPS,
              DS => T_DS, DNSKEY => T_DNSKEY);
my $rtype  = $types{$type} || T_A;

# build list of progressively-longer suffixes: ['com', 'example.com']
my @labels = split /\./, $target;
my @zones;
while (@labels) {
    push @zones, join('.', @labels);
    shift @labels;
}
@zones = reverse @zones;

my $r = EV::cares->new(timeout => 5, tries => 2);

sub one_query {
    my ($name, $t) = @_;
    my @res;
    my $done;
    $r->search($name, $t, sub { ($done, @res) = (1, @_); });
    my $stop = EV::timer 6, 0, sub { $done = 1 };
    EV::run until $done;
    return @res;
}

print "zone trace for $target\n", '=' x 60, "\n";

for my $i (0 .. $#zones) {
    my $z = $zones[$i];
    print '  ' x $i, "[$z]\n";

    my @ns = one_query($z, T_NS);
    if ($ns[0] == ARES_SUCCESS && @ns > 1) {
        print '  ' x ($i + 1), "NS:    $_\n" for sort @ns[1..$#ns];
    } else {
        print '  ' x ($i + 1), "NS:    none / ", EV::cares::strerror($ns[0]), "\n";
    }

    my ($s_ds,     @ds)     = one_query($z, T_DS);
    my ($s_dnskey, @dnskey) = one_query($z, T_DNSKEY);
    my $ds_n     = $s_ds     == ARES_SUCCESS ? scalar(grep ref, @ds)     : 0;
    my $dnskey_n = $s_dnskey == ARES_SUCCESS ? scalar(grep ref, @dnskey) : 0;
    printf "%sDNSSEC: DS=%d DNSKEY=%d\n",
        '  ' x ($i + 1), $ds_n, $dnskey_n;
}

# final lookup of the requested type
print "\n[$target $type]\n";
my @ans = one_query($target, $rtype);
my $st = $ans[0];
if ($st != ARES_SUCCESS) {
    print "  ", EV::cares::strerror($st), "\n";
} else {
    for my $rr (@ans[1..$#ans]) {
        if (ref $rr eq 'HASH') {
            print "  ",
                join(' ', map "$_=$rr->{$_}",
                    sort grep !ref $rr->{$_}, keys %$rr),
                "\n";
        } else {
            print "  $rr\n";
        }
    }
}
