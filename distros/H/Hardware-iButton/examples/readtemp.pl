#!/usr/bin/perl -w

use Hardware::iButton::Connection;

$c = new Hardware::iButton::Connection "/dev/ttyS8" or die;
$c->reset();

@bs = $c->scan("10"); # gets DS1920/DS1820 devices

#$Hardware::iButton::Connection::debug = 1;

#while (1) {
    foreach $b (@bs) {
	my $temp = $b->read_temperature_hires();
	print $b->serial(),": $temp C, ",($temp*9/5 +32)," F\n";
    }
#}
