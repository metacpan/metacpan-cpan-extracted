#!perl
use strict;
use warnings;

use Test::More;

use_ok("Imager::zxing");

my $ver = Imager::zxing::version();
print STDERR "\nlibzxing version $ver\n";

done_testing();
