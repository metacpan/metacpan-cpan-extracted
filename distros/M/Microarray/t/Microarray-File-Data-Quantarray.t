#! /usr/bin/perl -w

use strict;

use FindBin;
use Test::Harness;
use Test::More tests=>7;
use Test::Group;
use Test::Differences;
use Test::Deep;

BEGIN {
	use_ok('Microarray::File::Data::Quantarray');
}

my ($oFile,$oImage_File,$oImage_File2);

my $data_file = $FindBin::Bin.'/../test_files/quantarray.csv';
begin_skipping_tests "The test-file 'quantarray.csv' could not be found" unless (-e $data_file);  

test "Data file object creation" => sub {
	ok($oFile = quantarray_file->new($data_file),'object creation');
	isa_ok($oFile,'quantarray_file','quantarray_file object');
};
test "Header information" => sub {
	is($oFile->analysis_software,'ScanArray Express v3','analysis_software');
	cmp_ok($oFile->pixel_size,'==',5,'pixel_size');
	is($oFile->channel1_name,'Cyanine 3','channel1_name');
	is($oFile->channel2_name,'Cyanine 5','channel2_name');
	cmp_ok($oFile->num_channels,'==',2,'num_channels');
	is($oFile->slide_barcode,'7011','slide_barcode');
	is($oFile->channel1_image_file,'C:\Documents and Settings\Ken Choi\Desktop\Dimitra\Chr18 MMCT Validation\Cyanine3_240407 slide7011.tif','channel1_image_file');
	is($oFile->channel2_image_file,'C:\Documents and Settings\Ken Choi\Desktop\Dimitra\Chr18 MMCT Validation\Cyanine5_240407 slide7011.tif','channel2_image_file');
	is($oFile->gal_file,undef,'gal_file');
	is($oFile->scanner,'Model: ScanArray Express Serial No.: 432748','scanner');
	is($oFile->user_comment,undef,'user_comment');
	cmp_ok($oFile->channel1_pmt,'==',88,'channel1_pmt');
	cmp_ok($oFile->channel2_pmt,'==',81,'channel2_pmt');
	cmp_ok($oFile->channel1_laser,'==',88,'channel1_laser');
	cmp_ok($oFile->channel2_laser,'==',81,'channel2_laser');
};
test "Data" => sub {
	test "Spot 1" => sub {
		cmp_ok($oFile->block_row(0),'==',1,'block_row');
		cmp_ok($oFile->block_col(0),'==',1,'block_col');
		cmp_ok($oFile->spot_row(0),'==',1,'spot_row');
		cmp_ok($oFile->spot_col(0),'==',1,'spot_col');
		cmp_ok($oFile->spot_index(0),'==',1,'spot_index');
		is($oFile->feature_id(0),'RP11-504F6','feature_id');
		is($oFile->synonym_id(0),'none','synonym_id');
		cmp_ok($oFile->y_pos(0),'==',6742,'y_pos');
		cmp_ok($oFile->x_pos(0),'==',2027,'x_pos');
		cmp_ok($oFile->spot_diameter(0),'==',100,'spot_diameter');
		cmp_ok($oFile->spot_pixels(0),'==',286,'spot_pixels');
		cmp_ok($oFile->bg_pixels(0),'==',468,'b_pixels');
		cmp_ok($oFile->footprint(0),'==',9,'footprint');
		cmp_ok($oFile->flag_id(0),'==',3,'flag_id');
		
		cmp_ok($oFile->ch1_median_f(0),'==',1962,'ch1_median_f');
		cmp_ok($oFile->ch1_mean_f(0),'==',2709,'ch1_mean_f');
		cmp_ok($oFile->ch1_sd_f(0),'==',2360.03,'ch1_sd_f');
		cmp_ok($oFile->ch1_median_b(0),'==',956,'ch1_median_b');
		cmp_ok($oFile->ch1_mean_b(0),'==',1157,'ch1_mean_b');
		cmp_ok($oFile->ch1_sd_b(0),'==',838.7,'ch1_sd_b');
		cmp_ok($oFile->ch1_b1sd(0),'==',55.2,'ch1_b1sd');
		cmp_ok($oFile->channel1_quality(0),'==',36.7,'channel1_quality');
		cmp_ok($oFile->channel1_sat(0),'==',0,'channel1_sat');
		is((sprintf "%3.2f",$oFile->channel1_snr(0)),'2.34','channel1_snr');

		cmp_ok($oFile->ch2_median_f(0),'==',1610,'ch2_median_f');
		cmp_ok($oFile->ch2_mean_f(0),'==',2596,'ch2_mean_f');
		cmp_ok($oFile->ch2_sd_f(0),'==',2496.9,'ch2_sd_f');
		cmp_ok($oFile->ch2_median_b(0),'==',592,'ch2_median_b');
		cmp_ok($oFile->ch2_mean_b(0),'==',705,'ch2_mean_b');
		cmp_ok($oFile->ch2_sd_b(0),'==',564.54,'ch2_sd_b');
		cmp_ok($oFile->ch2_b1sd(0),'==',61.9,'ch2_b1sd');
		cmp_ok($oFile->channel2_quality(0),'==',47.2,'channel2_quality');
		cmp_ok($oFile->channel2_sat(0),'==',0,'channel2_sat');
		is((sprintf "%3.2f",$oFile->channel2_snr(0)),'2.85','channel2_snr');
	};
	test "Spot 15188" => sub {
		cmp_ok($oFile->block_row(15187),'==',7,'block_row');
		cmp_ok($oFile->block_col(15187),'==',3,'block_col');
		cmp_ok($oFile->spot_row(15187),'==',9,'spot_row');
		cmp_ok($oFile->spot_col(15187),'==',20,'spot_col');
		cmp_ok($oFile->spot_index(15187),'==',15188,'spot_index');
		is($oFile->feature_id(15187),'RP11-373G16','feature_id');
		is($oFile->synonym_id(15187),'none','synonym_id');
		cmp_ok($oFile->y_pos(15187),'==',35241,'y_pos');	
		cmp_ok($oFile->x_pos(15187),'==',14596,'x_pos');
		cmp_ok($oFile->spot_diameter(15187),'==',100,'spot_diameter');
		cmp_ok($oFile->spot_pixels(15187),'==',284,'spot_pixels');
		cmp_ok($oFile->bg_pixels(15187),'==',451,'b_pixels');
		cmp_ok($oFile->footprint(15187),'==',9,'footprint');
		cmp_ok($oFile->flag_id(15187),'==',3,'flag_id');
							
		cmp_ok($oFile->ch1_median_f(15187),'==',4433,'ch1_median_f');
		cmp_ok($oFile->ch1_mean_f(15187),'==',5786,'ch1_mean_f');
		cmp_ok($oFile->ch1_sd_f(15187),'==',4792.5,'ch1_sd_f');
		cmp_ok($oFile->ch1_median_b(15187),'==',1007,'ch1_median_b');
		cmp_ok($oFile->ch1_mean_b(15187),'==',1288,'ch1_mean_b');
		cmp_ok($oFile->ch1_sd_b(15187),'==',1195.31,'ch1_sd_b');
		cmp_ok($oFile->ch1_b1sd(15187),'==',79.2,'ch1_b1sd');
		cmp_ok($oFile->channel1_quality(15187),'==',62.3,'channel1_quality');
		cmp_ok($oFile->channel1_sat(15187),'==',0,'channel1_sat');
		is((sprintf "%3.2f",$oFile->channel1_snr(15187)),'3.71','channel1_snr');
					
		cmp_ok($oFile->ch2_median_f(15187),'==',4064,'ch2_median_f');
		cmp_ok($oFile->ch2_mean_f(15187),'==',4845,'ch2_mean_f');
		cmp_ok($oFile->ch2_sd_f(15187),'==',3221.57,'ch2_sd_f');
		cmp_ok($oFile->ch2_median_b(15187),'==',779,'ch2_median_b');
		cmp_ok($oFile->ch2_mean_b(15187),'==',972,'ch2_mean_b');
		cmp_ok($oFile->ch2_sd_b(15187),'==',828.55,'ch2_sd_b');
		cmp_ok($oFile->ch2_b1sd(15187),'==',90.8,'ch2_b1sd');
		cmp_ok($oFile->channel2_quality(15187),'==',75.7,'channel2_quality');
		cmp_ok($oFile->channel2_sat(15187),'==',0,'channel2_sat');
		is((sprintf "%3.2f",$oFile->channel2_snr(15187)),'4.90','channel2_snr');
	};
	test "Spot 27648" => sub {
		cmp_ok($oFile->block_row(27647),'==',12,'block_row');
		cmp_ok($oFile->block_col(27647),'==',4,'block_col');
		cmp_ok($oFile->spot_row(27647),'==',24,'spot_row');
		cmp_ok($oFile->spot_col(27647),'==',24,'spot_col');
		cmp_ok($oFile->spot_index(27647),'==',27648,'spot_index');
		is($oFile->feature_id(27647),'','feature_id');
		is($oFile->synonym_id(27647),'empty','synonym_id');
		cmp_ok($oFile->y_pos(27647),'==',60516,'y_pos');
		cmp_ok($oFile->x_pos(27647),'==',19835,'x_pos');
		cmp_ok($oFile->spot_diameter(27647),'==',100,'spot_diameter');
		cmp_ok($oFile->spot_pixels(27647),'==',285,'spot_pixels');
		cmp_ok($oFile->bg_pixels(27647),'==',453,'b_pixels');
		cmp_ok($oFile->footprint(27647),'==',19,'footprint');
		cmp_ok($oFile->flag_id(27647),'==',1,'flag_id');

		cmp_ok($oFile->ch1_median_f(27647),'==',1088,'ch1_median_f');
		cmp_ok($oFile->ch1_mean_f(27647),'==',1285,'ch1_mean_f');
		cmp_ok($oFile->ch1_sd_f(27647),'==',866.06,'ch1_sd_f');
		cmp_ok($oFile->ch1_median_b(27647),'==',1118,'ch1_median_b');
		cmp_ok($oFile->ch1_mean_b(27647),'==',1329,'ch1_mean_b');
		cmp_ok($oFile->ch1_sd_b(27647),'==',912.89,'ch1_sd_b');
		cmp_ok($oFile->ch1_b1sd(27647),'==',21.1,'ch1_b1sd');
		cmp_ok($oFile->channel1_quality(27647),'==',4.9,'channel1_quality');
		cmp_ok($oFile->channel1_sat(27647),'==',0,'channel1_sat');
		is((sprintf "%3.2f",$oFile->channel1_snr(27647)),'1.19','channel1_snr');

		cmp_ok($oFile->ch2_median_f(27647),'==',488,'ch2_median_f');
		cmp_ok($oFile->ch2_mean_f(27647),'==',723,'ch2_mean_f');
		cmp_ok($oFile->ch2_sd_f(27647),'==',641.78,'ch2_sd_f');
		cmp_ok($oFile->ch2_median_b(27647),'==',598,'ch2_median_b');
		cmp_ok($oFile->ch2_mean_b(27647),'==',744,'ch2_mean_b');
		cmp_ok($oFile->ch2_sd_b(27647),'==',593.67,'ch2_sd_b');
		cmp_ok($oFile->ch2_b1sd(27647),'==',18.6,'ch2_b1sd');
		cmp_ok($oFile->channel2_quality(27647),'==',8.1,'channel2_quality');
		cmp_ok($oFile->channel2_sat(27647),'==',0,'channel2_sat');
		is((sprintf "%3.2f",$oFile->channel2_snr(27647)),'0.82','channel2_snr');
	};
};
end_skipping_tests;

my $image_file = $FindBin::Bin.'/../test_files/7011_240407_Cyanine3.tif';
begin_skipping_tests "The test-file '7011_240407_Cyanine3.tif' could not be found" unless (-e $image_file);  

test "Image object creation" => sub {
	ok($oImage_File = quantarray_image->new($image_file),'image object creation');
	isa_ok($oImage_File,'quantarray_image','quantarray_image object');
};
test "Image object methods" => sub {
	is($oImage_File->protocol_name,'32k test array','protocol_name');
	is($oImage_File->protocol_description,'chromosome 21/X test array','protocol_description');
	is($oImage_File->image_user_name,'Ken Choi','image_user_name');
	is($oImage_File->image_datetime,'2007-04-24 11:53:44','image_datetime');
	is($oImage_File->image_scanner,'ScanArray Express 432748 432748','image_scanner');
	is($oImage_File->collection_software,'ScanArray Express, Microarray Analysis System 3.0.0.16','collection_software');
	is($oImage_File->image_lbarcode,undef,'image_lbarcode');
	is($oImage_File->fluor_description,'Cyanine 3','fluor_description');
	is($oImage_File->user_comment,undef,'user_comment');
	cmp_ok($oImage_File->scan_speed,'==',50,'scan_speed');
	cmp_ok($oImage_File->slide_barcode,'==',7011,'slide_barcode');
	cmp_ok($oImage_File->image_ubarcode,'==',7011,'image_ubarcode');
	cmp_ok($oImage_File->guess_slide_barcode,'==',7011,'guess_slide_barcode');
	cmp_ok($oImage_File->image_resolution,'==',5,'image_resolution');
	cmp_ok($oImage_File->fluor_id,'==',3,'fluor_id');
	cmp_ok($oImage_File->fluor_excitation,'==',550,'fluor_excitation');
	cmp_ok($oImage_File->fluor_emission,'==',570,'fluor_emission');
	cmp_ok($oImage_File->laser_id,'==',2,'laser_id');
	cmp_ok($oImage_File->filter_id,'==',3,'filter_id');
	cmp_ok($oImage_File->pmt_gain,'==',88,'pmt_gain');
	cmp_ok($oImage_File->laser_power,'==',88,'laser_power');
	cmp_ok($oImage_File->protocol_id,'==',501,'protocol_id');
};
test "Set new barcode" => sub {
	my $new_file = $FindBin::Bin.'/../test_files/changed_barcode.tif';
	my $new_barcode = 7012;
	cmp_ok($oImage_File->set_new_barcode($new_barcode,$new_file),'==',1,'set_new_barcode');
	cmp_ok($oImage_File->slide_barcode,'==',7012,'original image, new slide_barcode');
	is($oImage_File->image_lbarcode,undef,'original image, image_lbarcode');
	cmp_ok($oImage_File->image_ubarcode,'==',7012,'original image, image_ubarcode');
	ok($oImage_File2 = quantarray_image->new($FindBin::Bin.'/../test_files/changed_barcode.tif'),'image object creation');
	cmp_ok($oImage_File2->slide_barcode,'==',7012,'new image, slide_barcode');
	is($oImage_File2->image_lbarcode,undef,'new image, image_lbarcode');
	cmp_ok($oImage_File2->image_ubarcode,'==',7012,'new image, image_ubarcode');
	ok(unlink($new_file),"unlink $new_file");
};

end_skipping_tests;
