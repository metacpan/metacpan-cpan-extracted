#!/usr/bin/env perl -w

use strict;
use Test;
use FindBin qw/$Bin/;

BEGIN { plan tests => 10 }

use FindBin::Real;

foreach my $depth (1 .. 10) {
 if ($Bin =~ m!(.*?)((/[^/]+?){$depth})/!) {
   my $binx = $1 . $2; 
   ok($binx, FindBin::Real::BinDepth($depth));
 } else {
   ok(1, 1);
 }
}

exit;
