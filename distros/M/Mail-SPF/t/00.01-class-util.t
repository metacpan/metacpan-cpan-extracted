use strict;
use warnings;
use blib;

use Test::More tests => 15;

my $ipv4_address          = NetAddr::IP->new('192.168.0.1');
my $ipv6_address_v4mapped = NetAddr::IP->new('::ffff:192.168.0.1');
my $ipv6_address          = NetAddr::IP->new('2001:db8::1');


#### Class Compilation ####

BEGIN { use_ok('Mail::SPF::Util') }


#### hostname() ####

# We cannot really test Mail::SPF::Util->hostname, as on some systems it simply cannot get
# a fully qualified hostname and thus returns undef.


#### ipv4_address_to_ipv6() ####

{
    my $ip_address = eval { Mail::SPF::Util->ipv4_address_to_ipv6($ipv4_address) };
    isa_ok($ip_address,             'NetAddr::IP',      'Mail::SPF::Util->ipv4_address_to_ipv6() returns NetAddr::IP object');
    ok($ip_address == $ipv6_address_v4mapped,           'Mail::SPF::Util->ipv4_address_to_ipv6() yields correct IPv4-mapped IPv6 address');

    eval { Mail::SPF::Util->ipv4_address_to_ipv6('192.168.0.1') };
    isa_ok($@, 'Mail::SPF::EInvalidOptionValue',        'Mail::SPF::Util->ipv4_address_to_ipv6($string) exception');

    eval { Mail::SPF::Util->ipv4_address_to_ipv6($ipv6_address_v4mapped) };
    isa_ok($@, 'Mail::SPF::EInvalidOptionValue',        'Mail::SPF::Util->ipv4_address_to_ipv6($ipv6_address) exception');
}


#### ipv6_address_to_ipv4() ####

{
    my $ip_address = eval { Mail::SPF::Util->ipv6_address_to_ipv4($ipv6_address_v4mapped) };
    isa_ok($ip_address,             'NetAddr::IP',      'Mail::SPF::Util->ipv6_address_to_ipv4() returns NetAddr::IP object');
    ok($ip_address == $ipv4_address,                    'Mail::SPF::Util->ipv6_address_to_ipv4() yields correct IPv4 address');

    eval { Mail::SPF::Util->ipv6_address_to_ipv4('2001:db8::1') };
    isa_ok($@, 'Mail::SPF::EInvalidOptionValue',        'Mail::SPF::Util->ipv6_address_to_ipv4($string) exception');

    eval { Mail::SPF::Util->ipv6_address_to_ipv4($ipv4_address) };
    isa_ok($@, 'Mail::SPF::EInvalidOptionValue',        'Mail::SPF::Util->ipv6_address_to_ipv4($ipv4_address) exception');
}


#### ipv6_address_is_ipv4_mapped() ####

{
    my $is_v4mapped;

    $is_v4mapped = Mail::SPF::Util->ipv6_address_is_ipv4_mapped($ipv6_address_v4mapped);
    ok($is_v4mapped,                                    'Mail::SPF::Util->ipv6_address_is_ipv4_mapped($ipv6_address_v4mapped)');

    $is_v4mapped = Mail::SPF::Util->ipv6_address_is_ipv4_mapped($ipv6_address);
    ok((not $is_v4mapped),                              'Mail::SPF::Util->ipv6_address_is_ipv4_mapped($ipv6_address)');

    $is_v4mapped = Mail::SPF::Util->ipv6_address_is_ipv4_mapped($ipv4_address);
    ok((not $is_v4mapped),                              'Mail::SPF::Util->ipv6_address_is_ipv4_mapped($ipv4_address)');
}


#### ip_address_reverse() ####

{
    my $reverse_name;

    $reverse_name = Mail::SPF::Util->ip_address_reverse($ipv4_address);
    is($reverse_name, '1.0.168.192.in-addr.arpa.',      'Mail::SPF::Util->ip_address_reverse($ipv4_address)');

    $reverse_name = Mail::SPF::Util->ip_address_reverse($ipv6_address_v4mapped);
    is($reverse_name, '1.0.168.192.in-addr.arpa.',      'Mail::SPF::Util->ip_address_reverse($ipv6_address_v4mapped)');

    $reverse_name = Mail::SPF::Util->ip_address_reverse($ipv6_address);
    is($reverse_name, '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa.',
                                                    'Mail::SPF::Util->ip_address_reverse($ipv6_address)');
}


#### valid_domain_for_ip_address() ####

# TODO
