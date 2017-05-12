#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;
Gearman::Driver::Test->gearman_driver->run;