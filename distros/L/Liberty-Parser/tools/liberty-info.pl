#!/usr/bin/perl -w
use strict;
use Liberty::Parser;

my $i;
my $p = new Liberty::Parser;

my $file = shift;

my $g = $p->read_file($file);

my $lib_name = $p->get_group_name($g);
print "Library Name: $lib_name\n";
print $p->get_attr_with_value($g,"nom_temperature");
print $p->get_attr_with_value($g,"nom_voltage");
print $p->get_attr_with_value($g,"default_operating_conditions");
print $p->get_attr_with_value($g,"default_max_transition");
print $p->get_attr_with_value($g,"leakage_power_unit");
