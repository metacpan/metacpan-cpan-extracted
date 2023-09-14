#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;

use Test::Lib;
use My::Util;

my $ds9 = start_up();

ok( lives { $ds9->raise(); }, 'raise' )
  or note $@;

done_testing;
