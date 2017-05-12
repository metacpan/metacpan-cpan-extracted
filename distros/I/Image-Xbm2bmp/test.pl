# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Image::Xbm2bmp;
use strict;
eval{
	my $obj = Image::Xbm2bmp->new("test.xbm");
	$obj->to_bmp_file("test.bmp");
};
if($@){
	ok(0);	
}
else{
	ok(1); 
}

my $xbm_width = 32;
my $xbm_height = 9;
my @xbm_data = (	0x7c,0x3c,0x7c,0x3c,
					0xfe,0x7c,0xfe,0x7c,
					0xee,0xee,0xee,0xee,
					0xe0,0xee,0x60,0xee,
					0x70,0xfe,0x30,0xfe,
					0x38,0xec,0xe0,0xec,
					0x1c,0xe0,0xee,0xe0,
					0xfe,0x7e,0xfe,0x7e,
					0xfe,0x3c,0x7c,0x3c 
			);
eval{
	my $obj2 = new Image::Xbm2bmp;
	$obj2->load_xbm_data(\@xbm_data,$xbm_width,$xbm_height);
	$obj2->to_bmp_file("test2.bmp");
};
if($@){
	ok(0);
}
else{
	ok(1); 
}
