#!/usr/bin/env perl
# Mini dig: query a record type, optionally specifying servers.
# Usage:
#   perl eg/cli.pl example.com
#   perl eg/cli.pl @1.1.1.1 example.com MX
#   perl eg/cli.pl @8.8.8.8 @1.1.1.1 cloudflare.com HTTPS
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my %types = (
    A      => T_A,     AAAA   => T_AAAA,  CNAME  => T_CNAME,
    MX     => T_MX,    NS     => T_NS,    PTR    => T_PTR,
    SOA    => T_SOA,   SRV    => T_SRV,   TXT    => T_TXT,
    CAA    => T_CAA,   NAPTR  => T_NAPTR,
    SVCB   => T_SVCB,  HTTPS  => T_HTTPS, TLSA   => T_TLSA,
    DS     => T_DS,    DNSKEY => T_DNSKEY, RRSIG => T_RRSIG,
    ANY    => T_ANY,
);

my @servers;
while (@ARGV && $ARGV[0] =~ /^\@(.+)/) {
    push @servers, $1;
    shift;
}

my $name = shift or die <<USAGE;
usage: $0 [\@server ...] NAME [TYPE]
       TYPE is one of: ${\ join(' ', sort keys %types)}
USAGE
my $tname = uc(shift // 'A');
my $type  = $types{$tname} or die "unknown type: $tname\n";

my $r = EV::cares->new(@servers ? (servers => \@servers) : (), timeout => 5);

$r->search($name, $type, sub {
    my ($status, @res) = @_;
    if ($status != ARES_SUCCESS) {
        warn "$tname $name: " . EV::cares::strerror($status) . "\n";
        EV::break;
        return;
    }

    if    ($tname =~ /^(A|AAAA|NS|PTR)$/)
        { print "$tname $name: $_\n" for @res }
    elsif ($tname eq 'MX')
        { printf "MX %s: %d %s\n", $name, $_->{priority}, $_->{host} for @res }
    elsif ($tname eq 'SRV') {
        for (@res) {
            printf "SRV %s: %d %d %d %s\n",
                $name, $_->{priority}, $_->{weight}, $_->{port}, $_->{target};
        }
    }
    elsif ($tname eq 'TXT')
        { print "TXT $name: \"$_\"\n" for @res }
    elsif ($tname eq 'SOA') {
        my $s = $res[0];
        printf "SOA %s: %s %s serial=%d\n",
            $name, $s->{mname}, $s->{rname}, $s->{serial};
    }
    elsif ($tname eq 'CAA') {
        for (@res) {
            printf "CAA %s: %s%s \"%s\"\n",
                $name, ($_->{critical} ? '! ' : ''), $_->{property}, $_->{value};
        }
    }
    elsif ($tname eq 'HTTPS' || $tname eq 'SVCB') {
        for my $rr (@res) {
            unless (ref $rr eq 'HASH') {
                print "$tname $name: ", length($rr), " bytes raw\n";
                next;
            }
            my $params = '';
            for my $k (sort keys %{$rr->{params}}) {
                my $v = $rr->{params}{$k};
                $v = join(',', @$v) if ref $v eq 'ARRAY';
                $v = unpack 'H*', $v if $k eq 'ech';
                $params .= " $k=$v";
            }
            printf "%s %s: %d %s%s\n",
                $tname, $name, $rr->{priority},
                $rr->{target} ne '' ? $rr->{target} : '.', $params;
        }
    }
    elsif ($tname eq 'NAPTR') {
        for (@res) {
            printf "NAPTR %s: %d %d \"%s\" \"%s\" \"%s\" %s\n",
                $name, $_->{order}, $_->{preference},
                $_->{flags}, $_->{service}, $_->{regexp}, $_->{replacement};
        }
    }
    elsif ($tname eq 'TLSA') {
        for (@res) {
            next unless ref $_ eq 'HASH';
            printf "TLSA %s: %d %d %d %s\n", $name,
                $_->{cert_usage}, $_->{selector}, $_->{matching_type},
                unpack('H*', $_->{data});
        }
    }
    elsif ($tname eq 'DS') {
        for (@res) {
            next unless ref $_ eq 'HASH';
            printf "DS %s: %d %d %d %s\n", $name,
                $_->{key_tag}, $_->{algorithm}, $_->{digest_type},
                unpack('H*', $_->{digest});
        }
    }
    elsif ($tname eq 'DNSKEY') {
        for (@res) {
            next unless ref $_ eq 'HASH';
            printf "DNSKEY %s: flags=%d alg=%d %d-byte key\n", $name,
                $_->{flags}, $_->{algorithm}, length($_->{public_key});
        }
    }
    elsif ($tname eq 'RRSIG') {
        for (@res) {
            next unless ref $_ eq 'HASH';
            printf "RRSIG %s: covers=%d alg=%d signer=%s key_tag=%d expires=%d\n",
                $name, $_->{type_covered}, $_->{algorithm},
                $_->{signer_name}, $_->{key_tag}, $_->{sig_expiration};
        }
    }
    else {
        for my $rr (@res) {
            print "$tname $name: ", ref($rr) ? 'parsed' : length($rr) . ' bytes raw', "\n";
        }
    }
    EV::break;
});

EV::run;
