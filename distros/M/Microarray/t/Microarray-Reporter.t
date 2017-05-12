#!/usr/bin/perl -w

use strict;

use FindBin;
use Test::More tests=>28;
use Test::Differences;

#1
BEGIN {
	use_ok('Microarray::Reporter');
	use_ok('Microarray::Spot');
}

my ($oReporter);

# set qc defaults
$ENV{ _LOW_SIGNAL_ }  = 500;
$ENV{ _HIGH_SIGNAL_ }  = 65000;
$ENV{ _PERCEN_SAT_ }  = 10;
$ENV{ _MIN_SNR_ }  = 2;
$ENV{ _SIGNAL_QUALITY_ }  = 50;
$ENV{ _MIN_DIAMETER_ }  = 80;
$ENV{ _MAX_DIAMETER_ }  = 150;
$ENV{ _TARGET_DIAMETER_ }  = 100;
$ENV{ _MAX_DIAMETER_DEVIATION_ } = 10;

ok($oReporter = array_reporter->new('CTD-2023C19'),'object creation');
isa_ok($oReporter,'array_reporter','array_reporter object');


#### first, set up the spot objects
my $oSpot1 = array_spot->new();
my $oSpot2 = array_spot->new();
my $oSpot3 = array_spot->new();

my @aSpot_Methods = qw( 	spot_index block_row block_col spot_row spot_col 
					x_pos y_pos spot_diameter feature_id synonym_id 
					spot_pixels bg_pixels footprint flag_id ch1_mean_f 
					ch1_median_f ch1_sd_f ch1_mean_b ch1_median_b 
					ch1_sd_b ch1_b1sd channel1_quality channel1_sat 
					ch2_mean_f ch2_median_f ch2_sd_f ch2_mean_b ch2_median_b 
					ch2_sd_b ch2_b1sd channel2_quality channel2_sat );
my @aSpot1_Values = (21438,10,2,6,6,7454,48172,100,'CTD-2023C19','none',284,478,34,1,3045,1891,2930.1,5295,1081,15011.05,0,0,0,3128,623,3478.33,4827,746,14570.59,0,0,0);
my @aSpot2_Values = (21621,10,2,13,21,10295,49492,100,'CTD-2023C19','none',285,450,4,3,5393,5010,3591.41,1030,860,779.85,80,73,0,6404,6690,3924.91,760,608,596.98,88.1,81.4,0);
my @aSpot3_Values = (21805,10,2,21,13,8799,50994,100,'CTD-2023C19','none',284,451,5,3,5242,5173,3250.62,990,794,727.6,85.2,75.7,0,6141,6436,3657.47,696,540,552.35,89.1,81,0);
for (my $i=0; $i<@aSpot_Methods; $i++){
	my $method = $aSpot_Methods[$i];
	$oSpot1->$method($aSpot1_Values[$i]);
	$oSpot2->$method($aSpot2_Values[$i]);
	$oSpot3->$method($aSpot3_Values[$i]);
}

####

ok($oReporter->add_reporter_spot($oSpot1),'add_reporter_spot 1');
ok($oReporter->add_reporter_spot($oSpot2),'add_reporter_spot 2');
ok($oReporter->add_reporter_spot($oSpot3),'add_reporter_spot 3');

$oReporter->do_spot_qc;

cmp_ok($oReporter->reporter_id,'eq','CTD-2023C19','reporter_id');
cmp_ok($oReporter->get_reporter_replicates,'==',3,'get_reporter_replicates');
cmp_ok($oReporter->spots_passed_qc,'==',2,'CTD-2023C19 spots passed QC');
cmp_ok($oReporter->mean_ch1,'==',4490.5,'mean_ch1');
cmp_ok($oReporter->mean_ch2,'==',5698.5,'mean_ch2');
cmp_ok($oReporter->mean_ratios,'eq',0.788117500091488,'mean_ratios');
cmp_ok($oReporter->ratio_means,'eq',0.788014389751689,'ratio means');
cmp_ok($oReporter->mean_log_ratios,'eq',-0.343559536947397,'log_mean_ratios');
cmp_ok($oReporter->log_ratio_means,'eq',-0.343706120238892,'log_ratio means');

ok(my $hAnalysed_Data = $oReporter->get_reporter_ratios,'get_reporter_ratios');
eq_or_diff $hAnalysed_Data, {ch1_mean=>4490.5,M_mean_of_ratios=>-0.343559536947397,ch2_mean=>5698.5,M_ratio_of_means=>-0.343706120238892}, 'analysed data hash';
ok(my $aAll_Ch1 = $oReporter->all_ch1,'all_ch1');
eq_or_diff $aAll_Ch1, [4533,4448], 'all_ch1 array';
ok(my $aAll_Ch2 = $oReporter->all_ch2,'all_ch2');
eq_or_diff $aAll_Ch2, [5796,5601], 'all_ch2 array';
ok(my $aAll_Ratios = $oReporter->all_ratios,'all_ratios');
eq_or_diff $aAll_Ratios, [0.782091097308489,0.794143902874487], 'all_ratios array';
ok(my $aX_Pos = $oReporter->x_pos,'x_pos');
eq_or_diff $aX_Pos, [10295,8799], 'x_pos array';
ok(my $aY_Pos = $oReporter->y_pos,'y_pos');
eq_or_diff $aY_Pos, [49492,50994], 'y_pos array';


