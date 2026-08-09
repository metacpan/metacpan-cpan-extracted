#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Ereshkigal::IP qw( normalize_ip normalize_cidr );

#
# IPv4
#

is( normalize_ip('1.2.3.4'),         '1.2.3.4',         'valid IPv4 returned as is' );
is( normalize_ip('255.255.255.255'), '255.255.255.255', 'broadcast IPv4 returned as is' );

# leading zero octets are ambiguous, octal vs decimal wise, so they are
# refused rather than guessed at
is( normalize_ip('001.002.003.004'), undef, 'IPv4 with leading zero octets refused' );
is( normalize_ip('010.0.0.1'),       undef, 'IPv4 with a leading zero octet refused' );

is( normalize_ip('1.2.3'),     undef, 'short IPv4 refused' );
is( normalize_ip('1.2.3.4.5'), undef, 'long IPv4 refused' );
is( normalize_ip('1.2.3.256'), undef, 'out of range octet refused' );

#
# IPv6... long form, short form, and case variants all reduce to the same
# canonical form
#

is( normalize_ip('2001:0db8:0000:0000:0000:0000:0000:0001'), '2001:db8::1', 'long form IPv6 canonicalized' );
is( normalize_ip('2001:0DB8:0000:0000:0000:0000:0000:0001'), '2001:db8::1', 'uppercase long form canonicalized' );
is( normalize_ip('2001:db8:0:0::1'),                         '2001:db8::1', 'partially compressed canonicalized' );
is( normalize_ip('2001:db8::1'),                             '2001:db8::1', 'already canonical returned as is' );
is( normalize_ip('2001:DB8::1'),                             '2001:db8::1', 'uppercase short form lowercased' );

is( normalize_ip('::1'), '::1', 'loopback IPv6 ok' );

is( normalize_ip('2001:db8::1::2'), undef, 'double compression refused' );
is( normalize_ip('2001:db8:::1'),   undef, 'triple colon refused' );
is( normalize_ip('12345::1'),       undef, 'oversized group refused' );

#
# non-IP stuff
#

is( normalize_ip('not-an-ip'),    undef, 'random string refused' );
is( normalize_ip(''),             undef, 'empty string refused' );
is( normalize_ip(undef),          undef, 'undef refused' );
is( normalize_ip( ['1.2.3.4'] ),  undef, 'ref refused' );
is( normalize_ip('1.2.3.4/32'),   undef, 'CIDR refused' );
is( normalize_ip(' 1.2.3.4'),     undef, 'leading whitespace refused' );
is( normalize_ip("1.2.3.4\n"),    undef, 'trailing newline refused' );
is( normalize_ip('fe80::1%eth0'), undef, 'scope id refused' );

#
# normalize_cidr, IPv4... the host bits below the prefix are masked off so the
# network address is what comes back
#

is( normalize_cidr('1.2.3.0/24'),       '1.2.3.0/24',       'IPv4 network address returned as is' );
is( normalize_cidr('1.2.3.4/24'),       '1.2.3.0/24',       'IPv4 host bits masked off' );
is( normalize_cidr('10.0.0.0/8'),       '10.0.0.0/8',       'IPv4 /8 ok' );
is( normalize_cidr('192.168.1.130/25'), '192.168.1.128/25', 'IPv4 mid byte prefix masked' );
is( normalize_cidr('1.2.3.4/32'),       '1.2.3.4/32',       'IPv4 /32 keeps the whole address' );
is( normalize_cidr('1.2.3.4/0'),        '0.0.0.0/0',        'IPv4 /0 masks to all zero' );

is( normalize_cidr('1.2.3.0/33'),  undef, 'IPv4 prefix out of range refused' );
is( normalize_cidr('010.0.0.0/8'), undef, 'IPv4 leading zero octet refused' );

#
# normalize_cidr, IPv6... long form, case, and host bits all reduce to the same
# canonical masked network
#

is( normalize_cidr('2001:db8::/32'),       '2001:db8::/32',      'IPv6 network returned canonical' );
is( normalize_cidr('2001:0DB8:0000::/32'), '2001:db8::/32',      'IPv6 long uppercase form canonicalized' );
is( normalize_cidr('2001:db8::abcd/32'),   '2001:db8::/32',      'IPv6 host bits masked off' );
is( normalize_cidr('2001:db8:ffff::/33'),  '2001:db8:8000::/33', 'IPv6 mid byte prefix masked' );
is( normalize_cidr('2001:db8::1/128'),     '2001:db8::1/128',    'IPv6 /128 keeps the whole address' );
is( normalize_cidr('2001:db8::1/0'),       '::/0',               'IPv6 /0 masks to all zero' );

is( normalize_cidr('2001:db8::/129'), undef, 'IPv6 prefix out of range refused' );

#
# normalize_cidr, non-CIDR stuff
#

is( normalize_cidr('1.2.3.4'),         undef, 'bare IPv4 with no prefix refused' );
is( normalize_cidr('2001:db8::1'),     undef, 'bare IPv6 with no prefix refused' );
is( normalize_cidr('1.2.3.0/024'),     undef, 'IPv4 leading zero prefix refused' );
is( normalize_cidr('1.2.3.0/'),        undef, 'empty prefix refused' );
is( normalize_cidr('1.2.3.0/24/24'),   undef, 'extra prefix refused' );
is( normalize_cidr('not-a-cidr/24'),   undef, 'non-IP address refused' );
is( normalize_cidr('fe80::1%eth0/64'), undef, 'scope id refused' );
is( normalize_cidr('1.2.3.0/24 '),     undef, 'trailing whitespace refused' );
is( normalize_cidr("1.2.3.0/24\n"),    undef, 'trailing newline refused' );
is( normalize_cidr(''),                undef, 'empty string refused' );
is( normalize_cidr(undef),             undef, 'undef refused' );
is( normalize_cidr( ['1.2.3.0/24'] ),  undef, 'ref refused' );

done_testing;
