use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:all);

# network-dependent tests -- skip if no connectivity
my $r = EV::cares->new(timeout => 5, tries => 2);
my $can_resolve;

$r->resolve('google.com', sub {
    $can_resolve = 1 if $_[0] == ARES_SUCCESS;
});

my $t = EV::timer 6, 0, sub { EV::break };
EV::run;

unless ($can_resolve) {
    plan skip_all => 'no network connectivity';
}

# helper: run a single query with timeout
sub run_query {
    my ($code) = @_;
    my @result;
    my $done;
    $code->(sub { @result = @_; $done = 1 });
    my $t = EV::timer 10, 0, sub { $done = 1 };
    EV::run until $done;
    return @result;
}

# T_A
{
    my ($status, @addrs) = run_query(sub {
        $r->search('google.com', T_A, $_[0]);
    });
    is($status, ARES_SUCCESS, 'search T_A google.com');
    ok(@addrs > 0, 'T_A returned addresses');
    like($addrs[0], qr/^\d+\.\d+\.\d+\.\d+$/, 'T_A returned IPv4');
}

# T_AAAA
{
    my ($status, @addrs) = run_query(sub {
        $r->search('google.com', T_AAAA, $_[0]);
    });
    if ($status == ARES_SUCCESS) {
        ok(@addrs > 0, 'T_AAAA returned addresses');
        like($addrs[0], qr/:/, 'T_AAAA returned IPv6');
    } else {
        pass('T_AAAA not available (ok)');
        pass('skipped');
    }
}

# T_MX
{
    my ($status, @records) = run_query(sub {
        $r->search('google.com', T_MX, $_[0]);
    });
    is($status, ARES_SUCCESS, 'search T_MX google.com');
    ok(@records > 0, 'T_MX returned records');
    ok(ref $records[0] eq 'HASH', 'T_MX record is hashref');
    ok(exists $records[0]{priority}, 'T_MX has priority');
    ok(exists $records[0]{host}, 'T_MX has host');
}

# T_NS
{
    my ($status, @records) = run_query(sub {
        $r->search('google.com', T_NS, $_[0]);
    });
    is($status, ARES_SUCCESS, 'search T_NS google.com');
    ok(@records > 0, 'T_NS returned nameservers');
    like($records[0], qr/\.google\.com$/, 'T_NS looks like a hostname');
}

# T_TXT
{
    my ($status, @records) = run_query(sub {
        $r->search('google.com', T_TXT, $_[0]);
    });
    is($status, ARES_SUCCESS, 'search T_TXT google.com');
    ok(@records > 0, 'T_TXT returned records');
    ok(grep({ /v=spf/ } @records), 'T_TXT contains SPF record');
}

# T_SOA
{
    my ($status, @records) = run_query(sub {
        $r->search('google.com', T_SOA, $_[0]);
    });
    is($status, ARES_SUCCESS, 'search T_SOA google.com');
    ok(@records == 1, 'T_SOA returned one record');
    ok(ref $records[0] eq 'HASH', 'T_SOA record is hashref');
    for my $key (qw(mname rname serial refresh retry expire minttl)) {
        ok(exists $records[0]{$key}, "T_SOA has $key");
    }
}

# T_SRV
{
    my ($status, @records) = run_query(sub {
        $r->search('_imaps._tcp.gmail.com', T_SRV, $_[0]);
    });
    is($status, ARES_SUCCESS, 'search T_SRV');
    ok(@records > 0, 'T_SRV returned records');
    ok(ref $records[0] eq 'HASH', 'T_SRV record is hashref');
    for my $key (qw(priority weight port target)) {
        ok(exists $records[0]{$key}, "T_SRV has $key");
    }
}

# T_CAA
{
    my ($status, @records) = run_query(sub {
        $r->search('cloudflare.com', T_CAA, $_[0]);
    });
    is($status, ARES_SUCCESS, 'search T_CAA cloudflare.com');
    ok(@records > 0, 'T_CAA returned records');
    ok(ref $records[0] eq 'HASH', 'T_CAA record is hashref');
    for my $key (qw(critical property value)) {
        ok(exists $records[0]{$key}, "T_CAA has $key");
    }
}

# reverse (may fail if PTR not available from this resolver)
{
    my ($status, @hosts) = run_query(sub {
        $r->reverse('8.8.8.8', $_[0]);
    });
    ok(defined $status, 'reverse returned status');
    if ($status == ARES_SUCCESS) {
        ok(@hosts > 0, 'reverse returned hostnames');
        diag "8.8.8.8 => @hosts";
    } else {
        pass('reverse PTR not available: ' . EV::cares::strerror($status));
    }
}

# raw query
{
    my ($status, $buf) = run_query(sub {
        $r->query('google.com', C_IN, T_A, $_[0]);
    });
    is($status, ARES_SUCCESS, 'raw query T_A');
    ok(length($buf) > 12, 'raw response has DNS header + data');
}

# getnameinfo
{
    use Socket qw(pack_sockaddr_in inet_aton);
    my $sa = pack_sockaddr_in(80, inet_aton('8.8.8.8'));
    my ($status, $node, $service) = run_query(sub {
        $r->getnameinfo($sa, ARES_NI_NUMERICSERV, $_[0]);
    });
    ok(defined $status, 'getnameinfo returned status');
    if ($status == ARES_SUCCESS) {
        ok(defined $node, "getnameinfo node: $node");
        ok(!defined($service) || length($service), 'getnameinfo service present or undef');
    } else {
        pass('getnameinfo: ' . EV::cares::strerror($status));
        pass('skipped');
    }
}

done_testing;
