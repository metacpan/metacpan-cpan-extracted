use Test::More;

use_ok('IP::Decimal');

is(IP::Decimal::ipv4_to_decimal('127.0.0.1'), '2130706433', 'test IPv4 to Decimal');
is(IP::Decimal::decimal_to_ipv4('2130706433'), '127.0.0.1', 'test Decimal to IPv4');
is(IP::Decimal::ipv6_to_decimal('dead:beef:cafe:babe::f0ad'), '295990755076957304698079185533545803949', 'test IPv6 to Decimal');
is(IP::Decimal::decimal_to_ipv6('295990755076957304698079185533545803949'), 'dead:beef:cafe:babe::f0ad', 'test Decimal to IPv6');

done_testing();