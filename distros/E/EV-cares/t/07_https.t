use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:all);

# probe network first
my $r = EV::cares->new(timeout => 5, tries => 2);
my $can_resolve;
$r->resolve('cloudflare.com', sub { $can_resolve = 1 if $_[0] == ARES_SUCCESS });
my $t = EV::timer 6, 0, sub { EV::break };
EV::run;
plan skip_all => 'no network connectivity' unless $can_resolve;

# HTTPS record
my @got;
my $done;
$r->search('cloudflare.com', T_HTTPS, sub { @got = @_; $done = 1 });
my $t2 = EV::timer 6, 0, sub { $done = 1 };
EV::run until $done;

SKIP: {
    skip 'HTTPS unavailable: ' . EV::cares::strerror($got[0]), 5
        if $got[0] != ARES_SUCCESS;
    skip 'no HTTPS records returned (parser missing or empty answer)', 5
        unless @got > 1 && ref $got[1] eq 'HASH';

    pass('HTTPS record returned');
    my $rr = $got[1];
    ok(exists $rr->{priority}, 'priority present');
    ok(exists $rr->{target},   'target present');
    ok(ref $rr->{params} eq 'HASH', 'params is hashref');
    # commonly seen on cloudflare HTTPS records
    my $p = $rr->{params};
    ok(exists $p->{alpn}     ||
       exists $p->{ipv4hint} ||
       exists $p->{ipv6hint} ||
       exists $p->{port},
       'at least one common param parsed');
}

done_testing;
