use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:all);

# network-dependent tests -- skip if no connectivity.
# ARES_FLAG_EDNS asks the upstream resolver to advertise EDNS0 capability,
# which is required for DNSSEC record types (DS, DNSKEY, RRSIG, TLSA) to
# come back from many recursive resolvers.
my $r = EV::cares->new(timeout => 5, tries => 2, flags => ARES_FLAG_EDNS);
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
    SKIP: {
        skip 'T_A unavailable: ' . EV::cares::strerror($status), 3
            if $status != ARES_SUCCESS;
        is($status, ARES_SUCCESS, 'search T_A google.com');
        ok(@addrs > 0, 'T_A returned addresses');
        like($addrs[0], qr/^\d+\.\d+\.\d+\.\d+$/, 'T_A returned IPv4');
    }
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
    SKIP: {
        skip 'T_MX unavailable: ' . EV::cares::strerror($status), 5
            if $status != ARES_SUCCESS;
        is($status, ARES_SUCCESS, 'search T_MX google.com');
        ok(@records > 0, 'T_MX returned records');
        ok(ref $records[0] eq 'HASH', 'T_MX record is hashref');
        ok(exists $records[0]{priority}, 'T_MX has priority');
        ok(exists $records[0]{host}, 'T_MX has host');
    }
}

# T_NS
{
    my ($status, @records) = run_query(sub {
        $r->search('google.com', T_NS, $_[0]);
    });
    SKIP: {
        skip 'T_NS unavailable: ' . EV::cares::strerror($status), 3
            if $status != ARES_SUCCESS;
        is($status, ARES_SUCCESS, 'search T_NS google.com');
        ok(@records > 0, 'T_NS returned nameservers');
        like($records[0], qr/\.google\.com$/, 'T_NS looks like a hostname');
    }
}

# T_TXT
{
    my ($status, @records) = run_query(sub {
        $r->search('google.com', T_TXT, $_[0]);
    });
    SKIP: {
        skip 'T_TXT unavailable: ' . EV::cares::strerror($status), 3
            if $status != ARES_SUCCESS;
        is($status, ARES_SUCCESS, 'search T_TXT google.com');
        ok(@records > 0, 'T_TXT returned records');
        ok(grep({ /v=spf/ } @records), 'T_TXT contains SPF record');
    }
}

# T_SOA
{
    my ($status, @records) = run_query(sub {
        $r->search('google.com', T_SOA, $_[0]);
    });
    SKIP: {
        skip 'T_SOA unavailable: ' . EV::cares::strerror($status), 10
            if $status != ARES_SUCCESS;
        is($status, ARES_SUCCESS, 'search T_SOA google.com');
        ok(@records == 1, 'T_SOA returned one record');
        ok(ref $records[0] eq 'HASH', 'T_SOA record is hashref');
        for my $key (qw(mname rname serial refresh retry expire minttl)) {
            ok(exists $records[0]{$key}, "T_SOA has $key");
        }
    }
}

# T_SRV
{
    my ($status, @records) = run_query(sub {
        $r->search('_imaps._tcp.gmail.com', T_SRV, $_[0]);
    });
    SKIP: {
        skip 'T_SRV unavailable: ' . EV::cares::strerror($status), 7
            if $status != ARES_SUCCESS;
        is($status, ARES_SUCCESS, 'search T_SRV');
        ok(@records > 0, 'T_SRV returned records');
        ok(ref $records[0] eq 'HASH', 'T_SRV record is hashref');
        for my $key (qw(priority weight port target)) {
            ok(exists $records[0]{$key}, "T_SRV has $key");
        }
    }
}

# T_NAPTR (sip2sip.info commonly publishes NAPTR for SIP discovery)
{
    my ($status, @records) = run_query(sub {
        $r->search('sip2sip.info', T_NAPTR, $_[0]);
    });
    SKIP: {
        skip 'T_NAPTR unavailable: ' . EV::cares::strerror($status), 7
            unless $status == ARES_SUCCESS && @records;
        ok(ref $records[0] eq 'HASH', 'T_NAPTR record is hashref');
        for my $key (qw(order preference flags service regexp replacement)) {
            ok(exists $records[0]{$key}, "T_NAPTR has $key");
        }
    }
}

# T_CAA
{
    my ($status, @records) = run_query(sub {
        $r->search('cloudflare.com', T_CAA, $_[0]);
    });
    SKIP: {
        skip 'T_CAA unavailable: ' . EV::cares::strerror($status), 6
            if $status != ARES_SUCCESS;
        is($status, ARES_SUCCESS, 'search T_CAA cloudflare.com');
        ok(@records > 0, 'T_CAA returned records');
        ok(ref $records[0] eq 'HASH', 'T_CAA record is hashref');
        for my $key (qw(critical property value)) {
            ok(exists $records[0]{$key}, "T_CAA has $key");
        }
    }
}

# DNSSEC types use fresh resolver instances each.  c-ares 1.34 has a
# caching/parser quirk where querying multiple DNSSEC types (DS, DNSKEY,
# RRSIG) for the same name on the same channel returns zero records for
# every type past the first, even though status is ARES_SUCCESS.  Using a
# separate channel per type sidesteps it.

# T_DS (DNSSEC delegation signer)
{
    my $r2 = EV::cares->new(timeout=>5, tries=>2, flags => ARES_FLAG_EDNS);
    my ($status, @records) = run_query(sub {
        $r2->search('cloudflare.com', T_DS, $_[0]);
    });
    SKIP: {
        skip 'T_DS unavailable: ' . EV::cares::strerror($status), 5
            unless $status == ARES_SUCCESS && @records;
        ok(ref $records[0] eq 'HASH', 'T_DS record is hashref');
        for my $key (qw(key_tag algorithm digest_type digest)) {
            ok(exists $records[0]{$key}, "T_DS has $key");
        }
    }
}

# T_DNSKEY (DNSSEC public keys at zone apex)
{
    my $r2 = EV::cares->new(timeout=>5, tries=>2, flags => ARES_FLAG_EDNS);
    my ($status, @records) = run_query(sub {
        $r2->search('cloudflare.com', T_DNSKEY, $_[0]);
    });
    SKIP: {
        skip 'T_DNSKEY unavailable: ' . EV::cares::strerror($status), 5
            unless $status == ARES_SUCCESS && @records;
        ok(ref $records[0] eq 'HASH', 'T_DNSKEY record is hashref');
        for my $key (qw(flags protocol algorithm public_key)) {
            ok(exists $records[0]{$key}, "T_DNSKEY has $key");
        }
    }
}

# T_RRSIG -- many recursive resolvers SERVFAIL on standalone RRSIG queries
# (RRSIG is normally returned in the additional section alongside other
# DNSSEC records with the DO bit, not as a primary answer).  We still try
# it because the parser is the hand-written signer-name decoder we most
# want to exercise; just be tolerant of upstream refusal.
{
    my $r2 = EV::cares->new(timeout=>5, tries=>2, flags => ARES_FLAG_EDNS);
    my ($status, @records) = run_query(sub {
        $r2->search('cloudflare.com', T_RRSIG, $_[0]);
    });
    SKIP: {
        skip 'T_RRSIG unavailable: ' . EV::cares::strerror($status), 6
            unless $status == ARES_SUCCESS && @records && ref $records[0];
        ok(ref $records[0] eq 'HASH', 'T_RRSIG record is hashref');
        for my $key (qw(type_covered algorithm key_tag signer_name)) {
            ok(exists $records[0]{$key}, "T_RRSIG has $key");
        }
        like($records[0]{signer_name}, qr/^[\w.\-]*$/,
            'signer_name decoded as a printable domain string');
    }
}

# T_TLSA (DANE TLSA at a DANE-publishing service)
{
    my $r2 = EV::cares->new(timeout=>5, tries=>2, flags => ARES_FLAG_EDNS);
    my ($status, @records) = run_query(sub {
        $r2->search('_25._tcp.mail.protonmail.ch', T_TLSA, $_[0]);
    });
    SKIP: {
        skip 'T_TLSA unavailable: ' . EV::cares::strerror($status), 5
            unless $status == ARES_SUCCESS && @records && ref $records[0];
        ok(ref $records[0] eq 'HASH', 'T_TLSA record is hashref');
        for my $key (qw(cert_usage selector matching_type data)) {
            ok(exists $records[0]{$key}, "T_TLSA has $key");
        }
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
