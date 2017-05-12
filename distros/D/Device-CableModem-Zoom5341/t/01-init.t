#!usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 1;
use Device::CableModem::Zoom5341;

my $cm = Device::CableModem::Zoom5341->new;
isa_ok($cm, 'Device::CableModem::Zoom5341', "Object defined right");
