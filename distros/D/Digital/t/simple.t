#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use DigitalTestDriver;
use Digital;

my $digi = input( digitaltestdriver => 613 );

isa_ok($digi,'DigitalTestDriver');

is($digi->K,296.644,'Kelvin correct');
is($digi->C,23.494,'Celsius correct');
is($digi->F,74.2892,'Fahrenheit correct');

done_testing;

