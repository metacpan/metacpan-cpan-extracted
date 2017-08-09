use Test::More;

BEGIN {
    use_ok 'Device::HID';
}

use strict;
use warnings;

my $dev = Device::HID->new(vendor => 0x28DE, product => 0x1142);
SKIP: {
    skip "No steam controller detected", 3 unless defined $dev;
    use Test::HexString;
    $dev->timeout = 0.1;
    $dev->autodie;
    $dev->renew_on_timeout;

    my $buf;
    my $nbytes;
    ok defined($nbytes = $dev->read_data($buf, 24));
    is $nbytes, 24;
    is_hexstr substr($buf, 0, 2), "\x01\x00";
}

done_testing;
