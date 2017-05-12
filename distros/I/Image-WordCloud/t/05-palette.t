use strict;
use warnings;

use Test::More;
use Image::WordCloud;

#plan skip_all => "No palette tests at this time";

my $number_of_tests_run = 0;

my $wc = new Image::WordCloud;

my @rand_colors = $wc->_random_colors();
use Data::Dumper; print Dumper(\@rand_colors);

foreach my $c (@rand_colors) {
	isa_ok($c, 'ARRAY',		"_random_colors() returns array or arrayrefs");
	is(scalar(@$c), 3,		"_random_colors() arrayrefs have 3 values (RGB)");
	
	$number_of_tests_run += 2;
}

#dies_ok( sub { my $colors = $wc->random_palette(); }, "Dies when no 'count' is provided");
#
#$colors = $wc->_random_palette(count => 10);
#is( scalar @$colors, 10, 'Right number of colors with count' );
#
#$colors = $wc->_random_palette(count => 10, saturation => 0.8);
#is( scalar @$colors, 10, 'Right number of colors with saturation' );
#
#$colors = $wc->_random_palette(count => 10, value => 0.8);
#is( scalar @$colors, 10, 'Right number of colors with value' );
#
#$colors = $wc->_random_palette(count => 10, saturation => 0.8, value => 0.2);
#is( scalar @$colors, 10, 'Right number of colors with saturation and value' );
#
## Check for death with bad parameters
#dies_ok( sub { $wc->_random_palette(count => 'flurb') }, 									'Dies on non-integer number of colors' );
#dies_ok( sub { $wc->_random_palette(count => 10, saturation => 'flurb') }, 'Dies on non-integer saturation' );
#dies_ok( sub { $wc->_random_palette(count => 10, value => 'flurb') }, 			'Dies on non-integer value' );

done_testing( $number_of_tests_run );