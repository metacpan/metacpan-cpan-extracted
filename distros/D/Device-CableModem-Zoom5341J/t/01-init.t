#!usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 1;
use Device::CableModem::Zoom5341J;

my $cm = Device::CableModem::Zoom5341J->new;
isa_ok($cm, 'Device::CableModem::Zoom5341J', "Object defined right");
