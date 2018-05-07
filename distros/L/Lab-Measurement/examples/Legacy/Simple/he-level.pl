#!/usr/bin/perl

use strict;
use Lab::Instrument::IsoBus;
use Lab::Instrument::ILM;
use Lab::VISA;

# create an IsoBus VISA instrument
# the only parameter is a VISA interface description. serial port should work, 
# and I think a GPIB gateway device should work too, with the same syntax as in
# the Instrument constructor ($gpibadaptor,$gpibaddress). not tested though.
#
my $isobus=new Lab::Instrument::IsoBus("ASRL2");

# attach an ILM with IsoBus address 6 to that bus
#
my $ilm=new Lab::Instrument::ILM($isobus,6);

my $level=$ilm->get_level();

print "The current helium level is $level\%\n";

