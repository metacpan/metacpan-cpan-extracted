#!/usr/bin/perl -w

use strict;

use FindBin;
use Test::More tests=>5;
use Test::Group;
use Test::Differences;
use Test::Deep;

#1
BEGIN {
	use_ok('Microarray::Spot');
}

my ($oSpot);

#2
ok($oSpot = array_spot->new(1),'object creation');
isa_ok($oSpot,'array_spot','array_spot object');

my @aMethods = qw( 	spot_index block_row block_col spot_row spot_col 
					x_pos y_pos spot_diameter feature_id synonym_id 
					spot_pixels bg_pixels footprint flag_id ch1_mean_f 
					ch1_median_f ch1_sd_f ch1_mean_b ch1_median_b 
					ch1_sd_b ch1_b1sd channel1_quality channel1_sat 
					ch2_mean_f ch2_median_f ch2_sd_f ch2_mean_b ch2_median_b 
					ch2_sd_b ch2_b1sd channel2_quality channel2_sat spot_status );
my @aValues = (4,2,3,1,4,2588,6736,100,'RP13-486L5','none',280,436,7,3,3306,2071,3213.69,1143,883,859.79,57.5,43.6,0,3181,1891,3237.4,790,658,603.81,61.4,50.4,0,1);

#3
test "setters" => sub {
	for (my $i=0; $i<@aMethods; $i++){
		my $method = $aMethods[$i];
		my $value = $aValues[$i];
		cmp_ok($oSpot->$method($value),'eq',$oSpot->{"_$method"},"$method set $value");
	}
};

#4
test "getters" => sub {
	for (my $i=0; $i<@aMethods; $i++){
		my $method = $aMethods[$i];
		my $value = $aValues[$i];
		cmp_ok($oSpot->$method,'eq',$value,"$method get $value");
	}
};






