package Test::Unit;

use strict;
use warnings;
use parent 'Device::Modbus::Unit';

sub new {
    my $class = shift;
    return bless {}, $class;
}

1;
