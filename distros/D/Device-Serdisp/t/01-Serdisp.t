# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Serdisp.t'

use strict;
use warnings;

use Test::More tests => 7;

use_ok('Device::Serdisp');
use_ok('GD');

my $d = Device::Serdisp->new('USB:7c0/1501', 'ctinclud');
$d->init();
ok($d->width() > 0, 'Checking width > 0');
ok($d->height() > 0, 'Checking height > 0');

$d->clear();

my $image = GD::Image->new(128,64);
my $black = $image->colorAllocate(0,0,0);
my $white = $image->colorAllocate(255,255,255);

$image->transparent($black);
$image->arc(10,10,10,10,0,270, $white);
ok($d->copyGD($image), 'Copying GD image to display');

sleep(5);

$d->set_option("INVERT","1");
ok($d->get_option("INVERT"), "Invert display");
sleep(2);
$d->set_option("INVERT","0");
ok(!$d->get_option("INVERT"), "Re-invert display");

sleep(5);

undef $d;

