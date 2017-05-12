#!/usr/bin/env perl
use strict;
use warnings;
use Gearman::Driver;
my $driver = Gearman::Driver->new_with_options;
$driver->run;