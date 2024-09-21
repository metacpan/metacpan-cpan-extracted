#!/usr/bin/env perl

###################################################################
#### NOTE env-var TEMP_DIRS_KEEP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use utf8; # allow for utf8 in code (we have strings in utf8, filenames)

our $VERSION = '2.2';

use Test::More;
use Test2::Plugin::UTF8;

use File::Spec;
use File::Temp qw/tempdir cleanup/;
use FindBin;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use Image::DecodeQR::WeChat qw/
	modelsdir
	opencv_has_highgui_xs
	detect_and_decode_qr_xs
	detect_and_decode_qr
/;

# 0: nothing,
# > 9: add also XS verbose
my $VERBOSITY = 10;

# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = File::Temp::tempdir(CLEANUP=>1); # will not be erased if env var is set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my ($ret, $input_image_filename, $outbase);

#####################################################
# 1. firstly, try with an empty image (no qr codes in it):
#####################################################

$input_image_filename = File::Spec->catdir($FindBin::Bin, 'testimages', 'empty.jpg'),
$outbase = File::Spec->catdir($tmpdir, 'empty.out');

$ret = Image::DecodeQR::WeChat::detect_and_decode_qr({
	# run it with minimal arguments to see if defaults kick in
	'input' => $input_image_filename,
	'outbase' => $outbase,
});
ok(defined($ret), "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");
my ($payloads, $bboxes) = @$ret;

ok(defined($payloads), "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and payloads is defined.");
ok(ref($payloads)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and payloads is ARRAYref.");

ok(defined($bboxes), "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and bboxes is defined.");
ok(ref($bboxes)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and bboxes is ARRAYref.");

my $num_qr_codes_detected = scalar @$payloads;
is($num_qr_codes_detected, 0, "zero QR codes detected as expected for empty image.");

is($num_qr_codes_detected, 0, "zero QR codes detected");
is(scalar(@$ret), 2, "zero QR codes detected returned a 2-item array as expected.");
is(scalar(@$payloads), 0, "zero QR codes detected returned an empty payloads array as expected.");
is(scalar(@$bboxes), 0, "zero QR codes detected returned an empty bounding boxes array as expected.");

#####################################################
# 2. secondly, try with 4 QR codes
#####################################################

$input_image_filename = File::Spec->catdir($FindBin::Bin, 'testimages', 'complex_test.png');
$outbase = File::Spec->catdir($tmpdir, 'complex_test.out');

$ret = Image::DecodeQR::WeChat::detect_and_decode_qr({
	# run it with minimal arguments to see if defaults kick in
	'input' => $input_image_filename,
	'outbase' => $outbase,
});
ok(defined($ret), "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");
($payloads, $bboxes) = @$ret;

ok(defined($payloads), "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and payloads is defined.");
ok(ref($payloads)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and payloads is ARRAYref.");

ok(defined($bboxes), "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and bboxes is defined.");
ok(ref($bboxes)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$input_image_filename' and bboxes is ARRAYref.");

$num_qr_codes_detected = scalar @$payloads;
is($num_qr_codes_detected, 4, "zero QR codes detected 4 QR codes.");

is(scalar(@$ret), 2, "returned a 2-item array as expected.");
is($num_qr_codes_detected, 4, "4 QR codes detected");
is(scalar(@$payloads), 4, "returned 4 payloads as expected.");
is(scalar(@$bboxes), 4, "returned 4 bounding boxes as expected.");

for (0..$#$payloads){
	my $p = $payloads->[$_];
	is(ref($p), '', "payloads is a scalar");
	my $b = $bboxes->[$_];
	is(ref($b), 'ARRAY', "bounding boxes is a scalar");
	is(scalar(@$b), 4*2, "bounding boxes has 4 2d coordinates");
}

#done_testing;
#exit(0);

####################################################
## Now try the same but with detect_and_decode_qr_xs()
####################################################

#####################################################
# 1. firstly, try with an empty image (no qr codes in it):
#####################################################

$input_image_filename = File::Spec->catdir($FindBin::Bin, 'testimages', 'empty.jpg'),
$outbase = File::Spec->catdir($tmpdir, 'empty.out');

$ret = Image::DecodeQR::WeChat::detect_and_decode_qr_xs(
	$input_image_filename,
	Image::DecodeQR::WeChat::modelsdir(),
	$outbase,
	$VERBOSITY,
	0, # graphicaldisplayresult
	0  # dumpqrimagestofile
);

ok(defined($ret), "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");
($payloads, $bboxes) = @$ret;

ok(defined($payloads), "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and payloads is defined.");
ok(ref($payloads)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and payloads is ARRAYref.");

ok(defined($bboxes), "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and bboxes is defined.");
ok(ref($bboxes)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and bboxes is ARRAYref.");

$num_qr_codes_detected = scalar @$payloads;
is($num_qr_codes_detected, 0, "zero QR codes detected as expected for empty image.");

is(scalar(@$ret), 2, "zero QR codes detected returned a 2-item array as expected.");
is($num_qr_codes_detected, 0, "zero QR codes detected");
is(scalar(@$payloads), 0, "zero QR codes detected returned an empty payloads array as expected.");
is(scalar(@$bboxes), 0, "zero QR codes detected returned an empty bounding boxes array as expected.");

#####################################################
# 2. secondly, try with 4 QR codes
#####################################################

$input_image_filename = File::Spec->catdir($FindBin::Bin, 'testimages', 'complex_test.png');
$outbase = File::Spec->catdir($tmpdir, 'complex_test.out');

$ret = Image::DecodeQR::WeChat::detect_and_decode_qr_xs(
	$input_image_filename,
	Image::DecodeQR::WeChat::modelsdir(),
	$outbase,
	$VERBOSITY,
	0, # graphicaldisplayresult
	1, # dumpqrimagestofile
);

ok(defined($ret), "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");
($payloads, $bboxes) = @$ret;

ok(defined($payloads), "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and payloads is defined.");
ok(ref($payloads)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and payloads is ARRAYref.");

ok(defined($bboxes), "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and bboxes is defined.");
ok(ref($bboxes)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$input_image_filename' and bboxes is ARRAYref.");

$num_qr_codes_detected = scalar @$payloads;
is($num_qr_codes_detected, 4, "zero QR codes detected 4 QR codes.");

is(scalar(@$ret), 2, "returned a 2-item array as expected.");
is($num_qr_codes_detected, 4, "4 QR codes detected");
is(scalar(@$payloads), 4, "returned 4 payloads as expected.");
is(scalar(@$bboxes), 4, "returned 4 bounding boxes as expected.");

for (0..$#$payloads){
	my $p = $payloads->[$_];
	is(ref($p), '', "payloads is a scalar");
	my $b = $bboxes->[$_];
	is(ref($b), 'ARRAY', "bounding boxes is a scalar");
	is(scalar(@$b), 4*2, "bounding boxes has 4 2d coordinates");
}


# if you set env var TEMP_DIRS_KEEP=1 when running
# the temp files WILL NOT BE DELETED otherwise
# they are deleted automatically, unless some other module
# messes up with $File::Temp::KEEP_ALL
diag "temp dir: $tmpdir ...";
do {
	$File::Temp::KEEP_ALL = 0;
	File::Temp::cleanup;
	diag "temp files cleaned!";
} unless exists($ENV{'TEMP_DIRS_KEEP'}) && $ENV{'TEMP_DIRS_KEEP'}>0;

done_testing;
