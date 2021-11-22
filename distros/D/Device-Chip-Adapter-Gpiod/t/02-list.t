# -*- CPerl -*-

use Test::More tests => 1;

use Device::Chip::Adapter::Gpiod;

SKIP: {
    skip '$ENV{DCA_GPIOD_CHIP} and $ENV{DCA_GPIOD_NUMLINES} not set', 1
      unless exists $ENV{DCA_GPIOD_CHIP} && exists $ENV{DCA_GPIOD_NUM_LINES};

    my $chip = Device::Chip::Adapter::Gpiod->new(device => $ENV{DCA_GPIOD_CHIP});

    my $protocol = $chip->make_protocol('GPIO')->get();

    my @lines = $protocol->list_gpios();

    is(scalar @lines, $ENV{DCA_GPIOD_NUM_LINES});
}
