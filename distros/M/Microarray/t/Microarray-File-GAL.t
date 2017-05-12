#!/usr/bin/perl -w

use strict;

use Test::Harness;
use Test::More tests=>8;
use Test::Group;
use FindBin;

my $curr_dir = $FindBin::Bin;

BEGIN {
	use_ok('Microarray::File::GAL');
	$SIG{__WARN__} = \&trap_warn;
}

my $oGal1;

my $file = $FindBin::Bin.'/../test_files/padded.gal';
begin_skipping_tests "The test-file 'padded.gal' could not be found" unless (-e $file);  

test "Object creation" => sub {
	ok($oGal1 = gal_file->new($file),'object creation');
	isa_ok($oGal1,'gal_file','object');
};

test "Header import" => sub {
	cmp_ok($oGal1->header_rows,'==',55,'header parsing');
	cmp_ok($oGal1->data_cols,'==',6,'data columns');
	cmp_ok($oGal1->gal_type,'eq','v4.1','GAL type');
	cmp_ok($oGal1->get_header_value('Type'),'eq','GenePix ArrayList V1.0',"header 'Type'");
	cmp_ok($oGal1->get_header_value('BlockCount') ,'eq', '48',"header 'BlockCount'");
	cmp_ok($oGal1->get_header_value('BlockType') ,'eq', '0',"header 'BlockType'");
	cmp_ok($oGal1->get_header_value('URL') ,'eq', 'http://',"header 'URL'");
	cmp_ok($oGal1->get_header_value('Supplier'),'eq', 'Genetix Ltd.',"header 'Supplier'");
	cmp_ok($oGal1->get_header_value('ArrayerSoftwareName') ,'eq', 'MicroArraying',"header 'ArrayerSoftwareName'");
	cmp_ok($oGal1->get_header_value('ArrayerSoftwareVersion') ,'eq', 'QSoft XP Build 6400 (Revision 9)',"header 'ArrayerSoftwareVersion'");
};

test "Block coordinates" => sub {
	cmp_ok($oGal1->block_rows,'==',4,'block_rows');
	cmp_ok($oGal1->block_cols,'==',12,'block_cols');
	my @aBlock_X = (3984,8484,12984,17484,3984,8484,12984,17484,3984,8484,12984,17484,3984,8484,12984,17484,3984,8484,12984,17484,3984,8484,12984,17484,3984,8484,12984,17484,3984,8484,12984,17484,3984,8484,12984,17484,3984,8484,12984,17484,3984,8484,12984,17484,3984,8484,12984,17484);
	my @aBlock_Y = (8000,8000,8000,8000,12500,12500,12500,12500,17000,17000,17000,17000,21500,21500,21500,21500,26000,26000,26000,26000,30500,30500,30500,30500,35000,35000,35000,35000,39500,39500,39500,39500,44000,44000,44000,44000,48500,48500,48500,48500,53000,53000,53000,53000,57500,57500,57500,57500);
	for (my $i=1; $i<=$oGal1->block_count; $i++){
	
		cmp_ok($oGal1->block_x_origin($i),'==',$aBlock_X[$i-1],"block $i X");
		cmp_ok($oGal1->block_y_origin($i),'==',$aBlock_Y[$i-1],"block $i Y");
		cmp_ok($oGal1->block_feature_diameter($i),'==',100,"block $i feature diameter");
		

		my $x_features = $oGal1->block_x_features($i);
		cmp_ok($x_features,'==',27,"block $i X features");
		cmp_ok($oGal1->block_x_spacing($i),'==',166,"block $i X spacing");
		
		my $y_features = $oGal1->block_y_features($i);
		cmp_ok($y_features,'==',28,"block $i Y features");
		cmp_ok($oGal1->block_y_spacing($i),'==',160,"block $i Y spacing");
	}
};

test "Counts" => sub {
	cmp_ok($oGal1->block_count,'==',48,'block count');
	cmp_ok($oGal1->spot_count,'==',32640,'spot count');
};

test "Spot Information" => sub {
	# info should match direct methods
	# can't think of a better way of doing this other than taking a couple of random spots
	ok(my $hInfo1 = $oGal1->get_spot_info(1,2,3),'get_spot_info()');
	cmp_ok($hInfo1->{Name},'eq','RP11-142C4','sample spot 1 name');
	cmp_ok($hInfo1->{ID},'eq','none','sample spot 1 id');
	cmp_ok($hInfo1->{Annotation},'eq','PLATE_BARCODE;GENETIX S3002PLZ:','sample spot 1 ann');
	cmp_ok($hInfo1->{Name},'eq',$oGal1->get_spot_name(1,2,3),'get_spot_name(1,2,3)');
	cmp_ok($hInfo1->{ID},'eq',$oGal1->get_spot_id(1,2,3),'get_spot_id(1,2,3)');
	cmp_ok($hInfo1->{Annotation},'eq',$oGal1->get_spot_annotation(1,2,3),'get_spot_annotation(1,2,3)');

	ok(my $hInfo2 = $oGal1->get_spot_info(41,21,23),'get_spot_info()');
	cmp_ok($hInfo2->{Name},'eq','RP11-565B10','sample spot 2 name');
	cmp_ok($hInfo2->{ID},'eq','none','sample spot 2 id');
	cmp_ok($hInfo2->{Annotation},'eq','PLATE_BARCODE;GenetixS3008XJR:','sample spot 2 ann');
	cmp_ok($hInfo2->{Name},'eq',$oGal1->get_spot_name(41,21,23),'get_spot_name(41,21,23)');
	cmp_ok($hInfo2->{ID},'eq',$oGal1->get_spot_id(41,21,23),'get_spot_id(41,21,23)');
	cmp_ok($hInfo2->{Annotation},'eq',$oGal1->get_spot_annotation(41,21,23),'get_spot_annotation(41,21,23)');
};

my $depadded_file = $curr_dir.'/../test_files/depadded.gal';

test "File output" => sub {	
	ok(open(FILE,">",$depadded_file),'open FILE for writing');
	ok(my $string = $oGal1->file_string,'file_string output');
	print FILE $string,"print file_string to FILE";
	close FILE, "close FILE";
};

end_skipping_tests;

begin_skipping_tests "The test-file '$depadded_file' could not be found" unless (-e $depadded_file);  

test "Validate exported file" => sub {
	ok(my $oGal2 = gal_file->new($depadded_file),'object creation');
	my $pads = 0;
	
	# the two files should be the same, 
	# except that the new file lacks the block padding and incomplete row 
	test "Spot loop" => sub { 
		ok(my $gal_type = $oGal2->gal_type,'gal_type()');

		BLOCK:for (my $block=1; $block<=$oGal1->block_count; $block++){
			ROW:for (my $row=1; $row<=$oGal1->counted_rows($block); $row++){
				COL:for (my $col=1; $col<=$oGal1->counted_cols($block); $col++){
					
					my $name1 = $oGal1->get_spot_name($block,$col,$row);
					my $id1 = $oGal1->get_spot_id($block,$col,$row);
					unless ($name1 && ($name1 ne '')){
						$pads++;
						next;
					}
					
					ok(my $name2 = $oGal2->get_spot_name($block,$col,$row),"get_spot_name($block,$col,$row)");
					ok(my $id2 = $oGal2->get_spot_id($block,$col,$row),"get_spot_id($block,$col,$row)");
					
					if ($gal_type eq 'v4.1'){
						ok(my $comment1 = $oGal1->get_spot_annotation($block,$col,$row),"get_spot_annotation($block,$col,$row) file 1");
						ok(my $comment2 = $oGal2->get_spot_annotation($block,$col,$row),"get_spot_annotation($block,$col,$row) file 2");
						is($comment1,$comment2,'correct comments');
						is($name1,$name2,'correct names');
						is($id1,$id2,'correct IDs');
					} else {
						is($name1,$name2,'correct names');
						is($id1,$id2,'correct IDs');
					}
					
				}
			}
		} 
	};
	cmp_ok($pads,'==',1056,'padding rows removed');
	ok(unlink($depadded_file),"unlink $depadded_file");		
};

end_skipping_tests;

sub trap_warn {
	my $signal = shift;
	if ($signal =~ /TRL::Microarray::Microarray_File::Gal_File ERROR: Discrepency in column count for block/){
		return 1;
	} else {
		return 0;
	}
}