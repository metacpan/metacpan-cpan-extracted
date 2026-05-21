use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:all);

# --- ptr_name IPv4 ---
{
    is(EV::cares::ptr_name('192.0.2.1'), '1.2.0.192.in-addr.arpa',
       'IPv4 ptr_name');
    is(EV::cares::ptr_name('0.0.0.0'), '0.0.0.0.in-addr.arpa',
       'IPv4 zero address');
    is(EV::cares::ptr_name('255.255.255.255'), '255.255.255.255.in-addr.arpa',
       'IPv4 broadcast');
    is(EV::cares::ptr_name('127.0.0.1'), '1.0.0.127.in-addr.arpa',
       'IPv4 loopback');

    eval { EV::cares::ptr_name('256.0.0.1') };
    like($@, qr/invalid IPv4 octet/, 'rejects out-of-range octet');

    eval { EV::cares::ptr_name() };
    like($@, qr/missing IP/, 'rejects undef');

    eval { EV::cares::ptr_name('not-an-ip') };
    like($@, qr/not a recognized/, 'rejects garbage');

    eval { EV::cares::ptr_name('010.0.0.1') };
    like($@, qr/leading-zero/, 'rejects octal-ambiguous leading-zero octet');
}

# --- ptr_name IPv6 ---
{
    my $v6 = EV::cares::ptr_name('2001:db8::1');
    like($v6, qr/\.ip6\.arpa\z/, 'IPv6 ends in ip6.arpa');
    my $expect = '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa';
    is($v6, $expect, 'IPv6 nibble order matches RFC 3596');

    is(EV::cares::ptr_name('::1'),
       '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa',
       'IPv6 ::1 reverse');

    eval { EV::cares::ptr_name('2001:db8::xyz') };
    like($@, qr/invalid IPv6/, 'rejects invalid IPv6');
}

# --- parse_header: minimal response ---
{
    # synthetic: id=0x1234, flags=0x8180 (qr=1,rd=1,ra=1,rcode=0), qd=1, an=1, ns=0, ar=0
    my $buf = pack('nnnnnn', 0x1234, 0x8180, 1, 1, 0, 0);
    my $h = EV::cares::parse_header($buf);
    is($h->{id}, 0x1234, 'header id');
    is($h->{qr}, 1, 'qr flag');
    is($h->{rd}, 1, 'rd flag');
    is($h->{ra}, 1, 'ra flag');
    is($h->{ad}, 0, 'ad clear');
    is($h->{cd}, 0, 'cd clear');
    is($h->{rcode}, 0, 'rcode 0');
    is($h->{qdcount}, 1, 'qdcount');
    is($h->{ancount}, 1, 'ancount');
}

# --- parse_header: AD bit set (validated answer) ---
{
    # flags=0x81a0 -> qr=1, rd=1, ra=1, ad=1
    my $buf = pack('nnnnnn', 0, 0x81a0, 0, 0, 0, 0);
    my $h = EV::cares::parse_header($buf);
    is($h->{ad}, 1, 'AD bit set when present');
}

# --- parse_header: SERVFAIL ---
{
    # flags=0x8182 -> qr=1, rd=1, ra=1, rcode=2 (servfail)
    my $buf = pack('nnnnnn', 0, 0x8182, 1, 0, 0, 0);
    my $h = EV::cares::parse_header($buf);
    is($h->{rcode}, 2, 'rcode SERVFAIL');
    is($h->{ancount}, 0, 'no answers on servfail');
}

# --- parse_header: AA/TC + section counts ---
{
    # 0x8600 = qr=1, opcode=0, aa=1, tc=1, rd=0
    my $buf = pack('nnnnnn', 0xbeef, 0x8600, 0, 3, 1, 2);
    my $h = EV::cares::parse_header($buf);
    is($h->{id},      0xbeef, 'arbitrary id round-trips');
    is($h->{opcode},  0, 'opcode 0 (QUERY)');
    is($h->{aa},      1, 'aa bit');
    is($h->{tc},      1, 'tc bit');
    is($h->{rd},      0, 'rd cleared');
    is($h->{nscount}, 1, 'nscount');
    is($h->{arcount}, 2, 'arcount');
}

# --- parse_header: opcode UPDATE (RFC 2136) ---
{
    # opcode 5 (UPDATE), shifted left 11 -> 0x2800
    my $buf = pack('nnnnnn', 0, 0x2800, 0, 0, 0, 0);
    is(EV::cares::parse_header($buf)->{opcode}, 5,
        'opcode UPDATE decodes correctly');
}

# --- parse_header: short buffer ---
{
    eval { EV::cares::parse_header("\x00\x00\x00") };
    like($@, qr/too short/, 'parse_header rejects short buffer');
}

# --- getaddrinfo_all (bulk) ---
{
    my $r = EV::cares->new(lookups => 'f');
    my $got;
    $r->getaddrinfo_all(['localhost', 'localhost', 'no-such-host.invalid'],
        undef, { family => AF_INET }, sub { $got = $_[0] });
    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run until $got;
    is(scalar keys %$got, 2, 'getaddrinfo_all dedupes inputs');
    ok(exists $got->{localhost}, 'localhost key present');
    ok(exists $got->{'no-such-host.invalid'}, 'invalid name still keyed');
    is($got->{localhost}{status}, ARES_SUCCESS, 'localhost succeeded');
    ok(@{$got->{localhost}{addrs}} > 0, 'localhost has addrs');
}

# --- getaddrinfo_all: input validation + empty list ---
{
    my $r = EV::cares->new;
    eval { $r->getaddrinfo_all('not-an-arrayref', undef, undef, sub {}) };
    like($@, qr/arrayref/, 'getaddrinfo_all rejects non-arrayref');
    eval { $r->getaddrinfo_all([], undef, undef, 'not-a-coderef') };
    like($@, qr/CODE/, 'getaddrinfo_all rejects non-coderef');
    my $got;
    $r->getaddrinfo_all([], undef, undef, sub { $got = $_[0] });
    is_deeply $got, {}, 'getaddrinfo_all empty list -> empty hashref';

    $r->destroy;
    eval { $r->getaddrinfo_all(['x'], undef, undef, sub {}) };
    like($@, qr/destroyed/, 'getaddrinfo_all croaks on destroyed resolver');
}

done_testing;
