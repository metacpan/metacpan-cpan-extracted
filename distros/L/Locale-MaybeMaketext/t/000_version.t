#!perl
use strict;
use warnings;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use MaybeMaketextTestdata;

ok( $] >= 5.020, 'Checking perl version compatibility', $] );  ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing();
