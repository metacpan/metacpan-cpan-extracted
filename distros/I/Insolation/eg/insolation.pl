#!/usr/bin/perl
#
# Written by Travis Kent Beste
# Mon Sep 13 11:07:34 CDT 2010

use strict;
use warnings;

use lib qw (./lib ../lib);
use Insolation;

#----------------------------------------#
# main
#----------------------------------------#
my $insolation = new Insolation();
$insolation->set_latitude('44.915982');   # set latitude
$insolation->set_longitude('-93.228340'); # set longitude
$insolation->set_year('2010');            # set year
$insolation->set_month('10');             # set month
$insolation->calculate_insolation();      # calculate the insolation for the givin information

# get xml output
my $xml = $insolation->get_xml();
#print "$xml";

# get csv output
my $csv = $insolation->get_csv();
print "$csv";

my $month_energy = $insolation->get_ym_insolation('2010-10');
printf "insolation for 2010-10    : %9.2f\n", $month_energy;

my $day_energy = $insolation->get_ymd_insolation('2010-10-01');
printf "insolation for 2010-10-01 : %9.2f\n", $day_energy;

exit(0);
