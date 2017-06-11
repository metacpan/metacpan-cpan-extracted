#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

my $mod = 'Geo::Compass::Variation';

BEGIN {
    use_ok( 'Geo::Compass::Variation' ) || print "Bail out!\n";
}

diag( "Testing Geo::Compass::Variation $Geo::Compass::Variation::VERSION, Perl $], $^X" );

can_ok($mod, 'mag_dec');
can_ok($mod, 'mag_inc');

done_testing;
