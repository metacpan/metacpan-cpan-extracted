use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN { use_ok('Device::WallyHome') }

BEGIN {
    ok(defined Device::WallyHome->VERSION, 'version defined');

    throws_ok(sub{ my $device = Device::WallyHome->new() }, qr/Attribute \(token\) is required at/, 'required token attribute');

    my $device = Device::WallyHome->new(token => 'test-token');

    ok(defined $device, 'instantiate device object');
}
