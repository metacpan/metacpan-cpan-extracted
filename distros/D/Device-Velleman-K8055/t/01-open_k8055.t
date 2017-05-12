use Device::Velleman::K8055 qw(:all);
use Test::More tests => 1;
use strict;
use warnings;

is(OpenDevice(0),0, "Can open the K8055 device 0");

CloseDevice();