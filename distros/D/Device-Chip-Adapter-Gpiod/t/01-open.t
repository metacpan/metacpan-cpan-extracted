# -*- CPerl -*-

use Test::More tests => 3;

require_ok('Device::Chip::Adapter::Gpiod');

SKIP: {
    skip '$ENV{DCA_GPIOD_CHIP} not set', 2 unless exists $ENV{DCA_GPIOD_CHIP};

    my $chip = Device::Chip::Adapter::Gpiod->new(device => $ENV{DCA_GPIOD_CHIP});
    isa_ok($chip, 'Device::Chip::Adapter::Gpiod');

    my $protocol = $chip->make_protocol('GPIO')->get;
    isa_ok($protocol, 'Device::Chip::Adapter::Gpiod');
}
