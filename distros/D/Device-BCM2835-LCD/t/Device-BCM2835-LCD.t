#!perl
use Test::More tests => 4;
BEGIN { use_ok('Device::BCM2835::LCD') };


$foo = Device::BCM2835::LCD->new();
if ($foo) {
	pass("Module load");
	} 
else {
	fail("Module load");
	}

# Quick sanity test to make sure we
# can toggle GPIOs....
use Device::BCM2835;
ok(Device::BCM2835::init(), "GPIO Init");

Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_GPIO_P1_24,&Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
my $gpiolevel = Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_GPIO_P1_24);
if ($gpiolevel == 0)
        {
	# GPIO is low, try to set it high
        Device::BCM2835::gpio_set(&Device::BCM2835::RPI_GPIO_P1_24);
        }
else {
	# GPIO was high, try setting it low
        Device::BCM2835::gpio_clr(&Device::BCM2835::RPI_GPIO_P1_24);
        }
# re-read the GPIO level, has it changed as requested?
my $newgpiolevel = Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_GPIO_P1_24);
if ($gpiolevel == $newgpiolevel)
        {
        fail("GPIO access");
        }
else {
	pass("GPIO access");
	}

