#!/usr/bin/env perl

use strict;
use warnings;

# Always use latest and greatest Neaf, no matter what's in the @INC
use FindBin qw($Bin);
use File::Basename qw(basename dirname);
use lib dirname($Bin)."/lib";
use MVC::Neaf;

# Add some flexibility to run alongside other examples
my $script = basename(__FILE__);

MVC::Neaf->static( "/examples" => $Bin, buffer => 1024, dir_index=>1 );

MVC::Neaf->run;
