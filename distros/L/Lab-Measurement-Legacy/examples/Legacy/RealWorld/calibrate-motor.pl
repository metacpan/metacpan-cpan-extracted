#!/usr/bin/perl

use strict;

use Lab::Instrument;
use Lab::Instrument::PD11042;

my $source=new Lab::Instrument::PD11042(
        connection_type=>'RS232',
        port => 'COM2',
);

