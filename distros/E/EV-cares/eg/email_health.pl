#!/usr/bin/env perl
# Email deliverability/posture check: MX, SPF, DMARC, MTA-STS, DKIM.
# Usage: perl eg/email_health.pl example.com
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my $domain = shift or die "usage: $0 DOMAIN\n";

my $r = EV::cares->new(timeout => 5, tries => 2);
my $pending = 0;
my %out;

sub check {
    my ($key, $name, $type, $extract) = @_;
    $pending++;
    $r->search($name, $type, sub {
        my ($status, @res) = @_;
        $out{$key} = $status == ARES_SUCCESS
            ? $extract->(@res)
            : '(' . EV::cares::strerror($status) . ')';
        EV::break unless --$pending;
    });
}

check 'MX', $domain, T_MX, sub {
    join('; ', map "$_->{priority} $_->{host}",
        sort { $a->{priority} <=> $b->{priority} } @_);
};
check 'SPF', $domain, T_TXT, sub {
    my @x = grep /^v=spf1/i, @_;
    @x ? join(' | ', @x) : 'no SPF found';
};
check 'DMARC', "_dmarc.$domain", T_TXT, sub {
    my @x = grep /^v=DMARC1/i, @_;
    @x ? $x[0] : 'no DMARC found';
};
check 'MTA-STS', "_mta-sts.$domain", T_TXT, sub {
    my @x = grep /^v=STSv1/i, @_;
    @x ? $x[0] : 'no MTA-STS TXT';
};
check 'TLS-RPT', "_smtp._tls.$domain", T_TXT, sub {
    my @x = grep /^v=TLSRPTv1/i, @_;
    @x ? $x[0] : 'no TLS-RPT';
};
for my $sel (qw(default selector1 selector2 google k1 mail s1 s2)) {
    check "DKIM/$sel", "$sel._domainkey.$domain", T_TXT, sub {
        my @x = grep /v=DKIM1/i, @_;
        @x ? substr($x[0], 0, 80) . (length($x[0]) > 80 ? '...' : '') : '(none)';
    };
}

EV::run;

print "Email posture for $domain\n", '=' x 50, "\n";
my @order = ('MX', 'SPF', 'DMARC', 'MTA-STS', 'TLS-RPT',
             grep /^DKIM/, sort keys %out);
for my $k (@order) {
    printf "%-12s %s\n", $k, $out{$k} // '?';
}
