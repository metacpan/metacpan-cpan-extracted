#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use DigitalTestDriverOverload;
use Digital;

my $digi = input( digitaltestdriveroverload => 613 );

isa_ok($digi,'DigitalTestDriverOverload');

is($digi->C,23.494,'Celsius correct');
is($digi,23.494,'Overload gives back celsius');
is($digi * 10,234.94,'Multiplication with overload');
is($digi - 5,18.494,'Substraction with overload');
is($digi + 5,28.494,'Addition with overload');
ok($digi < 25,'Numeric compare with overload');

done_testing;

