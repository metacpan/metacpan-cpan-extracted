#!/usr/bin/perl 

use strict;
use warnings;

use Device::PiLite;

my $p = Device::PiLite->new();

$p->all_off();

$p->character(1,2,"X");

for ( 1 .. 14 )
{
	sleep 1;
	$p->scroll(-1);
}


$p->all_off();
