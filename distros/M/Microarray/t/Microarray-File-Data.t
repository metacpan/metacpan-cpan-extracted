#! /usr/bin/perl -w

use strict;

use FindBin;
use Test::Harness;
use Test::More tests=>7;
use Test::Group;
use Test::Differences;
use Test::Deep;

BEGIN {
	use_ok('Microarray::File::Data');
}

my ($oFile1,$oFile2,$oSpot1,$oSpot2,$oSpot3);

my $data_file1 = $FindBin::Bin.'/../test_files/bluefuse_output.xls';
begin_skipping_tests "The test-file 'bluefuse_output.xls' could not be found" unless (-e $data_file1);  

test "BlueFuse object creation" => sub {
	ok($oFile1 = data_file->new($data_file1),'object creation');
	isa_ok($oFile1,'bluefuse_file','bluefuse_file object');
	is($oFile1->guess_barcode,'bluefuse','guess_barcode');
};

test "Spot object tests 1" => sub {
	test "Individual spot retrieval" => sub {
		ok($oSpot1 = $oFile1->spot_object(1),'get spot 1');
		cmp_ok($oSpot1->block_row,'==',1,'block_row');
		cmp_ok($oSpot1->block_col,'==',1,'block_col');
		cmp_ok($oSpot1->spot_row,'==',1,'spot_row');
		cmp_ok($oSpot1->spot_col,'==',1,'spot_col');
		cmp_ok($oSpot1->spot_index,'==',1,'spot_index');
		is($oSpot1->feature_id,'RP11-1137J16','feature_id');
		is($oSpot1->synonym_id,'RP11-1137J16','synonym_id');
		cmp_ok($oSpot1->channel1_signal,'==',436.126,'channel1_signal');
		cmp_ok($oSpot1->channel2_signal,'==',114.35,'channel2_signal');
		cmp_ok($oSpot1->ch1_mean_f,'==',436.126,'ch1_mean_f');
		cmp_ok($oSpot1->ch2_mean_f,'==',114.35,'ch2_mean_f');
		cmp_ok($oSpot1->ch1_median_b,'==',1,'ch1_median_b');
		cmp_ok($oSpot1->ch2_median_b,'==',1,'ch2_median_b');
		cmp_ok($oSpot1->channel1_quality,'==',0.15,'channel1_quality');
		cmp_ok($oSpot1->channel2_quality,'==',0.13,'channel2_quality');
		cmp_ok($oSpot1->x_pos,'==',128,'x_pos');
		cmp_ok($oSpot1->y_pos,'==',138,'y_pos');
		cmp_ok($oSpot1->spot_diameter,'==',6.38,'spot_diameter');
		is($oSpot1->flag_id,'E','flag_id');
		is($oFile1->number_spots,undef,'number_spots');
		cmp_ok($oFile1->spot_count,'==',33696,'spot_count');
	};
	test "Set spot objects and spot retrieval" => sub {
		ok($oFile1->set_spot_objects,'set_spot_objects');
		ok($oSpot2 = $oFile1->spot_object(18273),'get spot 18273');
		cmp_ok($oSpot2->block_row,'==',7,'block_row');
		cmp_ok($oSpot2->block_col,'==',3,'block_col');
		cmp_ok($oSpot2->spot_row,'==',1,'spot_row');
		cmp_ok($oSpot2->spot_col,'==',21,'spot_col');
		cmp_ok($oSpot2->spot_index,'==',18273,'spot_index');
		is($oSpot2->feature_id,'RP11-573G9','feature_id');
		is($oSpot2->synonym_id,'RP11-573G9','synonym_id');
		cmp_ok($oSpot2->channel1_signal,'==',806.789,'channel1_signal');
		cmp_ok($oSpot2->channel2_signal,'==',733.357,'channel2_signal');
		cmp_ok($oSpot2->ch1_mean_f,'==',806.789,'ch1_mean_f');
		cmp_ok($oSpot2->ch2_mean_f,'==',733.357,'ch2_mean_f');
		cmp_ok($oSpot2->ch1_median_b,'==',1,'ch1_median_b');
		cmp_ok($oSpot2->ch2_median_b,'==',1,'ch2_median_b');
		cmp_ok($oSpot2->channel1_quality,'==',1,'channel1_quality');
		cmp_ok($oSpot2->channel2_quality,'==',1,'channel2_quality');
		cmp_ok($oSpot2->x_pos,'==',2586,'x_pos');
		cmp_ok($oSpot2->y_pos,'==',5534,'y_pos');
		cmp_ok($oSpot2->spot_diameter,'==',18.48,'spot_diameter');
		is($oSpot2->flag_id,'B','flag_id');
		is($oFile1->number_spots,33696,'number_spots');
		cmp_ok($oFile1->spot_count,'==',33696,'spot_count');
	};
};
test "Signal and ratio calculations 1" => sub {
	cmp_ok($oFile1->channel1_signal(0),'==',436.126,'channel1_signal');
	cmp_ok($oFile1->channel2_signal(0),'==',114.35,'channel2_signal');
	cmp_ok($oFile1->channel1_snr(0),'==',0.15,'channel1_snr');
	cmp_ok($oFile1->channel2_snr(0),'==',0.13,'channel2_snr');
	cmp_ok($oFile1->log2_ratio(0),'==',1.931,'log2_ratio');
	$oFile1->flip;
	cmp_ok($oFile1->log2_ratio(0),'==',-1.931,'flip log2_ratio');
};

end_skipping_tests;

my $data_file2 = $FindBin::Bin.'/../test_files/quantarray.csv';
begin_skipping_tests "The test-file 'quantarray.csv' could not be found" unless (-e $data_file2);  

test "Quantarray object creation" => sub {
	ok($oFile2 = quantarray_file->new($data_file2),'object creation');
	isa_ok($oFile2,'quantarray_file','quantarray_file object');
	is($oFile2->guess_barcode,'quantarray.csv','guess_barcode');
};

test "Spot object tests 2" => sub {
	test "Set spot objects and spot retrieval" => sub {
		ok($oFile2->set_spot_objects,'set_spot_objects');
		ok($oSpot3 = $oFile2->spot_object(1),'get spot 1');
		cmp_ok($oSpot3->block_row,'==',1,'block_row');
		cmp_ok($oSpot3->block_col,'==',1,'block_col');
		cmp_ok($oSpot3->spot_row,'==',1,'spot_row');
		cmp_ok($oSpot3->spot_col,'==',1,'spot_col');
		cmp_ok($oSpot3->spot_index,'==',1,'spot_index');
		is($oSpot3->feature_id,'RP11-504F6','feature_id');
		is($oSpot3->synonym_id,'none','synonym_id');
		cmp_ok($oSpot3->channel1_signal,'==',1753,'channel1_signal');
		cmp_ok($oSpot3->channel2_signal,'==',2004,'channel2_signal');
		cmp_ok($oSpot3->ch1_mean_f,'==',2709,'ch1_mean_f');
		cmp_ok($oSpot3->ch2_mean_f,'==',2596,'ch2_mean_f');
		cmp_ok($oSpot3->ch1_median_b,'==',956,'ch1_median_b');
		cmp_ok($oSpot3->ch2_median_b,'==',592,'ch2_median_b');
		cmp_ok($oSpot3->channel1_quality,'==',36.7,'channel1_quality');
		cmp_ok($oSpot3->channel2_quality,'==',47.2,'channel2_quality');
		cmp_ok($oSpot3->x_pos,'==',2027,'x_pos');
		cmp_ok($oSpot3->y_pos,'==',6742,'y_pos');
		cmp_ok($oSpot3->spot_diameter,'==',100,'spot_diameter');
		cmp_ok($oSpot3->flag_id,'==',3,'flag_id');
		is($oFile2->number_spots,27648,'number_spots');
		cmp_ok($oFile2->spot_count,'==',27648,'spot_count');
	};
};
test "Signal and ratio calculations 2" => sub {
	cmp_ok($oFile2->channel1_signal(0),'==',1753,'channel1_signal');
	cmp_ok($oFile2->channel2_signal(0),'==',2004,'channel2_signal');
	is((sprintf "%4.3f",$oFile2->channel1_snr(0)),'2.339','channel1_snr');
	is((sprintf "%4.3f",$oFile2->channel2_snr(0)),'2.852','channel2_snr');
	is((sprintf "%4.3f",$oFile2->log2_ratio(0)),'-0.193','log2_ratio');
	$oFile2->flip;
	is((sprintf "%4.3f",$oFile2->log2_ratio(0)),'0.193','flip log2_ratio');
};

end_skipping_tests;
