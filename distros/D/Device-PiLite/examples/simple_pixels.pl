#!/usr/bin/perl 

use strict;
use warnings;

use Device::PiLite;

my $p = Device::PiLite->new();

$p->all_off();

foreach my $col ( 1 .. $p->columns() )
{
	foreach my $row ( 1 .. $p->rows() )
	{
		$p->pixel_on($col, $row);
	}
}
foreach my $col ( 1 .. $p->columns())
{
	foreach my $row ( 1 .. $p->rows())
	{
		$p->pixel_off($col, $row);
	}
}

$p->all_off();
