# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Device-BCM2835-NES.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More qw( no_plan );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

BEGIN {use_ok('Device::BCM2835::NES') };
require_ok('Device::BCM2835::NES');

can_ok('Device::BCM2835::NES',qw(new addController init read translateButtons cycle));

my $nes = Device::BCM2835::NES->new();

isa_ok($nes,'Device::BCM2835::NES');

ok(1 == $nes->init(),'test_init');
ok(1 == $nes->addController(Device::BCM2835::NES::RPI_GPIO_P1_13),'test_add');

my @btns = $nes->read();
my $c    = scalar(@btns);
is($c,1,'read_count');
is($btns[0],0,'read_value');

