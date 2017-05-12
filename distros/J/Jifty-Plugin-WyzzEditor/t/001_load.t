# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 1;
use strict;
use warnings;
use lib qw(lib);

use_ok ( 'Jifty::Plugin::WyzzEditor' ); 

