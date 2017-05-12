#!/usr/bin/perl
use v5.14;
use warnings;
use Device::PCDuino;

# Take input on one pin and mirror it to the output on another

use constant INPUT_PIN  => 3;
use constant OUTPUT_PIN => 2;


set_input( INPUT_PIN );
set_output( OUTPUT_PIN );

while(1) {
    my $input = input( INPUT_PIN );
    output( OUTPUT_PIN, $input );
    sleep(1);
}
