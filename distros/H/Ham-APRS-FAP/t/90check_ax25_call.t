# validate the check_ax25_call function

use Test;

BEGIN { plan tests => 6 };
use Ham::APRS::FAP qw(check_ax25_call);

ok(check_ax25_call('OH7LZB'), 'OH7LZB', 'Failed to check a callsign without SSID');
ok(check_ax25_call('OH7LZB-9'), 'OH7LZB-9', 'Failed to check a callsign with SSID -9');
ok(check_ax25_call('OH7LZB-15'), 'OH7LZB-15', 'Failed to check a callsign with SSID -15');

ok(check_ax25_call('OH7LZB-16'), undef, 'Failed to check a callsign with SSID -16, should return undef');
ok(check_ax25_call('OH7LZB-166'), undef, 'Failed to check a callsign with SSID -166, should return undef');
ok(check_ax25_call('OH7LZBXXX'), undef, 'Failed to check an invalid callsign, should return undef');

