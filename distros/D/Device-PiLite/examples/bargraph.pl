#!/usr/bin/perl 

use strict;
use warnings;

use Device::PiLite;

my $p = Device::PiLite->new();

$p->all_off();

foreach my $i ( 1 .. 14 )
{
	$p->bargraph($i, int(rand(100)));
}
