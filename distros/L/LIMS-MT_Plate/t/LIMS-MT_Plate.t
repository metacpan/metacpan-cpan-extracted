#! /usr/bin/perl -w

use strict;

use Test::Harness;
use Test::More tests=>13;
use Test::Group;
use Test::Differences;
use Test::Deep;
use Test::Exception;

# 1,2
BEGIN {
	use_ok('LIMS::MT_Plate');
	use_ok('LIMS::MT_Plate_File');
	$SIG{__WARN__} = \&trap_warn;
}


my $oTube = tube->new('tube');
my $oPlate_96_1 = mt_96->new('96well_1');
my $oPlate_96_2 = mt_plate->new('96well_2',96);
my $oPlate_96_3 = mt_96->new('96well_3',96);
my $oPlate_96_4 = mt_96->new('96well_4',96);
my $oPlate_96_5 = mt_96->new('96well_5',96);
my $oPlate_96_6 = mt_96->new('96well_6',96);
my $oPlate_96_7 = mt_96->new('96well_7',96);
my $oPlate_384 = mt_384->new('384well');
my $oPlate_1536 = mt_1536->new('1536well');

# 3
test "objects" => sub {
	isa_ok($oTube,'tube','tube object');
	isa_ok($oPlate_96_1,'mt_96','mt_96 object');
	isa_ok($oPlate_384,'mt_384','mt_384 object');
	isa_ok($oPlate_1536,'mt_1536','mt_1536 object');
	isa_ok($oPlate_96_2,'mt_96','mt_plate object');
	isa_ok($oPlate_96_3,'mt_96','mt_96 object');
	isa_ok($oPlate_96_4,'mt_96','mt_96 object');
	isa_ok($oPlate_96_5,'mt_96','mt_96 object');
	isa_ok($oPlate_96_6,'mt_96','mt_96 object');
	isa_ok($oPlate_96_7,'mt_96','mt_96 object');
};

# 4
test "barcodes" => sub {
	is($oPlate_96_1->barcode,'96well_1','barcode');
	is($oPlate_96_2->barcode,'96well_2','barcode');
	is($oPlate_384->barcode,'384well','barcode');
	is($oPlate_1536->barcode,'1536well','barcode');
};

# 5
test "start wells filled" => sub {
	cmp_ok($oPlate_96_1->wells_filled,'==',0,'0 wells_filled');
	cmp_ok($oPlate_96_2->wells_filled,'==',0,'0 wells_filled');
};

my @aSamples = ();
my @aSamples_b = ();
my @aSamples_c = ();
my @a8_Samples = ();
my @a12_Samples = ();

for (my $i=1; $i<=96; $i++){
	push (@aSamples,"sample $i");
	push (@aSamples_b,"sample_b $i");
	push (@aSamples_c,"sample_c $i");
	next if ($i > 12);
	push (@a12_Samples,"12_sample $i");
	next if ($i > 8);
	push (@a8_Samples,"8_sample $i");
}

$oPlate_96_1->fill_wells(\@aSamples);
$oPlate_96_2->fill_wells('1A','12H',\@aSamples);
$oPlate_96_3->fill_rows(['A'..'H'],\@aSamples_b);
$oPlate_96_4->fill_cols([1..12],\@aSamples_c);
$oPlate_96_5->fill_row('A',\@a12_Samples);
$oPlate_96_6->fill_col(1,\@a8_Samples);
$oPlate_96_6->fill_well('B2','sample 9','cosmid clone');

# 6
test "replace samples" => sub {
	dies_ok { $oPlate_96_6->fill_well('A1','sample x') } "can't replace";
	ok($oPlate_96_6->can_replace,'can_replace()');
	lives_ok { $oPlate_96_6->fill_well('A1','sample x') } 'can replace';
	ok($oPlate_96_6->warn_dont_replace,'warn_dont_replace()');
	lives_ok { $oPlate_96_6->fill_well('A1','sample x') } 'warn replace';
};

# 7
test "wells filled" => sub {
	cmp_ok($oPlate_96_1->wells_filled,'==',96,'96 wells_filled');
	cmp_ok($oPlate_96_2->wells_filled,'==',96,'96 wells_filled');
	cmp_ok($oPlate_96_3->wells_filled,'==',96,'96 wells_filled');
	cmp_ok($oPlate_96_4->wells_filled,'==',96,'96 wells_filled');
	cmp_ok($oPlate_96_5->wells_filled,'==',12,'12 wells_filled');
	cmp_ok($oPlate_96_6->wells_filled,'==',9,'9 wells_filled');
	cmp_ok($oPlate_96_6->samples_in_rowcol(1),'==',8,"8 samples_in_rowcol(1)");
	cmp_ok($oPlate_96_6->samples_in_rowcol('B'),'==',2,"2 samples_in_rowcol('B')");
	is($oPlate_96_6->rowcol_is_empty('A'),undef,"rowcol_is_empty('A')");
	cmp_ok($oPlate_96_6->rowcol_is_empty(3),'==',1,"rowcol_is_empty(3) returns 1");
	is($oPlate_96_6->rowcol_is_full('A'),undef,"rowcol_is_full('A')");
	cmp_ok($oPlate_96_6->rowcol_is_full(1),'==',1,"rowcol_is_full(1) returns 1");
	cmp_ok($oPlate_96_6->rowcol_not_full('A'),'==',11,"rowcol_not_full('A') returns 11");
	is($oPlate_96_6->empty_well('A1'),'sample x',"empty_well('A1')");
	$oPlate_96_6->count_filled_wells;
	is($oPlate_96_6->samples_in_rowcol('A'),undef,"now 0 samples_in_rowcol('A')");
};

my $aSample_Types = [];
for (my $i=0;$i<32;$i++){
	$aSample_Types->[$i] = 'cosmid clone';
	$aSample_Types->[$i+32] = 'PAC clone';
	$aSample_Types->[$i+64] = 'BAC clone';	
}

# 8
test "sample types" => sub {
	# set
	ok($oPlate_96_1->all_sample_types('cosmid clone'),'all_sample_types same');
	ok($oPlate_96_2->all_sample_types($aSample_Types),'all_sample_types from list');
	ok($oPlate_96_6->sample_type('A1','BAC clone'),'sample_type');
	
	# get
	is($oPlate_96_1->sample_type('A1'),'cosmid clone','sample_type');
	is($oPlate_96_2->sample_type('B1'),'cosmid clone','sample_type');
	is($oPlate_96_2->sample_type('D1'),'PAC clone','sample_type');
	is($oPlate_96_2->sample_type('G1'),'BAC clone','sample_type');
	is($oPlate_96_6->sample_type('A1'),'BAC clone','sample_type');
};

# 9
test "well_names" => sub {
	my $aWell_Names;
	ok($aWell_Names = $oPlate_96_1->well_names,'well_names');
	is($aWell_Names->[0],'A1','default well_names');
	is($aWell_Names->[12],'B1','default well_names');
	is($aWell_Names->[95],'H12','default well_names');
	ok($oPlate_96_1->well_format('col'),"well_format('col')");
	ok($aWell_Names = $oPlate_96_1->well_names,'well_names again');
	is($aWell_Names->[0],'A1','default well_names');
	is($aWell_Names->[12],'E2','default well_names');
	is($aWell_Names->[95],'H12','default well_names');
};

# 10
test "samples" => sub {
	is($oPlate_96_1->get_sample_name('A1'),'sample 1','sample A1');
	is($oPlate_96_1->get_sample_name('A12'),'sample 12','sample A12');
	is($oPlate_96_1->get_sample_name('D8'),'sample 44','sample D8');
	is($oPlate_96_1->get_sample_name('F5'),'sample 65','sample F5');
	is($oPlate_96_1->get_sample_name('H12'),'sample 96','sample H12');
	eq_or_diff $oPlate_96_1->all_samples,\@aSamples,'all_samples';
	eq_or_diff $oPlate_96_1->wells_empty,[],'wells_empty';
	$oPlate_96_1->well_format('row');
	eq_or_diff $oPlate_96_1->filled_wells,$oPlate_96_1->well_names,'filled_wells';
	eq_or_diff $oPlate_96_6->filled_wells,['B1','B2','C1','D1','E1','F1','G1','H1'],'filled_wells';
};

# 11
test "plate join" => sub {
	$oPlate_384->add_plate($oPlate_96_1,'A1');
	cmp_ok($oPlate_384->wells_filled,'==',96,'96 wells_filled');
	$oPlate_384->add_plate($oPlate_96_3,'A2');
	cmp_ok($oPlate_384->wells_filled,'==',192,'192 wells_filled');
	$oPlate_384->add_plate($oPlate_96_4,'B1');
	cmp_ok($oPlate_384->wells_filled,'==',288,'288 wells_filled');
	$oPlate_384->add_plate($oPlate_96_6,'B2');
	cmp_ok($oPlate_384->wells_filled,'==',296,'296 wells_filled');

	is($oPlate_384->get_sample_name('A1'),'sample 1','sample A1');
	is($oPlate_384->get_sample_name('A24'),'sample_b 12','sample A24');
	is($oPlate_384->get_sample_name('B1'),'sample_c 1','sample B1');
	is($oPlate_384->get_sample_name('D4'),'sample 9','sample D4');
	is($oPlate_384->sample_type('D4'),'cosmid clone','sample_type D4');

	$oPlate_96_5->combine_plates($oPlate_96_6);
	cmp_ok($oPlate_96_5->wells_filled,'==',20,'20 wells filled in combine_plates');
	eq_or_diff $oPlate_96_5->filled_wells,['A1','A2','A3','A4','A5','A6','A7','A8','A9','A10','A11','A12','B1','B2','C1','D1','E1','F1','G1','H1'],'filled_wells';
	eq_or_diff $oPlate_96_5->row_contents('B'),['8_sample 2','sample 9','empty','empty','empty','empty','empty','empty','empty','empty','empty','empty'],"row_contents('B')";
	eq_or_diff $oPlate_96_5->col_contents(2),['12_sample 2','sample 9','empty','empty','empty','empty','empty','empty'],"col_contents(2)";
};

# 12
test "plate format" => sub {
	cmp_ok($oPlate_96_5->is_row('A'),'==',1,"is_row('A')");
	is($oPlate_96_5->is_row('I'),undef,"is_row('I')");
	
	cmp_ok($oPlate_96_5->is_col(1),'==',1,"is_col(1)");
	is($oPlate_96_5->is_col(13),undef,"is_col(13)");
	
	cmp_ok($oPlate_96_5->row_or_col(1),'eq','col',"row_or_col(1)");
	cmp_ok($oPlate_96_5->row_or_col('A'),'eq','row',"row_or_col('A')");
	is($oPlate_96_5->row_or_col(13),undef,"row_or_col(13)");
	is($oPlate_96_5->row_or_col('I'),undef,"row_or_col('I')");	
	
	cmp_ok($oPlate_384->is_row('A'),'==',1,"is_row('A')");
	is($oPlate_384->is_row('Q'),undef,"is_row('Q')");
	
	cmp_ok($oPlate_384->is_col(1),'==',1,"is_col(1)");
	is($oPlate_384->is_col(25),undef,"is_col(25)");
};

# 13
test "overload operators" => sub {
	ok(($oPlate_384 > $oPlate_96_1),'gt overload');
	ok(($oPlate_96_1 < $oPlate_384),'lt overload');
	ok(($oPlate_96_1 ^ $oPlate_96_2),'eq overload');
};


sub trap_warn {
	my $signal = shift;
	if ($signal =~ /Not allowed to replace sample 'sample x' of plate '96well_6'in well 'A1' with sample 'sample x'/){
		return 1;
	} else {
		return 0;
	}
}
