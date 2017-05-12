#!/usr/bin/perl
use v5.14;
use warnings;
use Device::PCDuino;

# Output the analog value of an ADC pin
use constant ADC_INPUT_PIN => 0;

while(1) {
    my $input = input_adc( ADC_INPUT_PIN );
    say "Input pin " . ADC_INPUT_PIN . ": $input";
    sleep(1);
}
