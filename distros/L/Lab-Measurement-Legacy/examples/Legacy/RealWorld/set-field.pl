#!/usr/bin/perl

use strict;

use Lab::Instrument;
use Lab::Instrument::OI_IPS;

my $magnet=new Lab::Instrument::OI_IPS(
        connection_type=>'VISA_GPIB',
        gpib_address => 24,
		max_current => 123.8,    # A
		max_sweeprate => 0.0167, # A/s
		soft_fieldconstant => 0.13731588, # T/A
		can_reverse => 1,
		can_use_negative_current => 1,
);

unless (@ARGV > 0) {
    print "Usage: $0 target-field\n";
    exit;
}

my $field=$ARGV[0];

print "Our sweep target is $field T\n";

my $fc=$magnet->get_fieldconstant();
print "Our field constant is $fc T/A\n";

my $current=$field/$fc;
print "Our sweep target is then $current A\n";

my $rate=$magnet->get_sweeprate();
print "Our sweep rate is $rate A/s\n";
my $tr=$rate*$fc;
print "Our sweep rate is also $tr T/s\n";

print "setting field... ";
$magnet->set_field($field);
print "done.\n";
