#!/usr/bin/env perl

###################################################################
#### NOTE env-var TEMP_DIRS_KEEP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

our $VERSION = '2.2';

use utf8; # allow for utf8 in code (we have strings in utf8, filenames)

use Test::More;
use Test2::Plugin::UTF8;

use File::Spec;
use File::Temp qw/tempdir cleanup/;
use FindBin;

use Image::DecodeQR::WeChat qw/
	modelsdir
	opencv_has_highgui_xs
	detect_and_decode_qr_xs
	detect_and_decode_qr
/;

# This checks calling 'detect_and_decode_qr_xs()' with 6 scalars (correct)
# array of 6 scalars (should be correct),
# 7 scalars (wrong, must be caught)
# array of 7 scalars (wrong, must be caught)
# after realising that as it is it complains
# when an array of 6 scalars is passed to detect_and_decode_qr_xs()
# To fix it to accept also array I have added
#   PROTOTYPE: @
# in XS code. (Note: it already had PROTOTYPES: ENABLE)

# 0: nothing,
# > 9: add also XS verbose
my $VERBOSITY = 10;
my $GRAPHICAL_OUTPUT = 0;
my $DUMP_IMAGES_AND_DATA_TO_FILES = 1;

# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = File::Temp::tempdir(CLEANUP=>1); # will not be erased if env var is set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $testdata = {
	'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'japh.png'),
	'outbase' => File::Spec->catdir($tmpdir, 'japh.out'),
	'expected-payloads' => [
		'Just another Perl hacker'
	]
};

# or by finding our share-dir and giving it to it
my $modelsdir = Image::DecodeQR::WeChat::modelsdir();
ok(-d $modelsdir, "models dir exists in '$modelsdir'") or BAIL_OUT("can not continue!");

my $testimg = $testdata->{'test-in-file'};
my $expected = $testdata->{'expected-payloads'};
my $num_expected = scalar @$expected;
my $outbase = exists($testdata->{'outbase'})&&defined($testdata->{'outbase'}) ? $testdata->{'outbase'} : undef;

ok(-f $testimg, "test image exists in '$testimg'.") or BAIL_OUT("can not continue!");

# call it with 6 scalars
my $ret = Image::DecodeQR::WeChat::detect_and_decode_qr_xs(
	$testimg,
	$modelsdir,
	undef,
	$VERBOSITY,
	0,
	0
);
ok(defined($ret), "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");

# call it with an array of 6 scalars
my @params = (
	$testimg,
	$modelsdir,
	undef,
	$VERBOSITY,
	0,
	0
);
$ret = Image::DecodeQR::WeChat::detect_and_decode_qr_xs(@params);
ok(defined($ret), "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");

# call it with 1 scalar and an array of 5 scalars (as expected)
@params = (
	$modelsdir,
	undef,
	$VERBOSITY,
	0,
	0
);
$ret = Image::DecodeQR::WeChat::detect_and_decode_qr_xs($testimg, @params);
ok(defined($ret), "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");

# call it with 1 scalar and an array of 5 scalars (as expected)
@params = (
	$testimg,
	$modelsdir,
	undef,
	$VERBOSITY,
	0
);
$ret = Image::DecodeQR::WeChat::detect_and_decode_qr_xs(@params, 0);
ok(defined($ret), "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : called on '$testimg' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");

#######
### these should all fail
#######

# call it with 7 scalars (one more than expected) - it should fail
$ret = eval {
	Image::DecodeQR::WeChat::detect_and_decode_qr_xs(
		$testimg,
		$modelsdir,
		undef,
		$VERBOSITY,
		0,
		0,
		1000 # one more params than expected
	)
};
ok($@, "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : illegal calling with 7 scalars caught (one more than expected).");

# call it with an array of 7 scalars (one more than expected)
@params = (
	$testimg,
	$modelsdir,
	undef,
	$VERBOSITY,
	0,
	0,
	1000
);
ok($@, "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : illegal calling with an array of 7 scalars caught (one more than expected).");

# call it with 5 scalars (one less than expected) - it should fail
$ret = eval {
	Image::DecodeQR::WeChat::detect_and_decode_qr_xs(
		$testimg,
		$modelsdir,
		undef,
		$VERBOSITY,
		0,
		# 0 # less than expected
	)
};
ok($@, "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : illegal calling with 5 scalars caught (one less than expected).");

# call it with an array of 5 scalars (one less than expected)
@params = (
	$testimg,
	$modelsdir,
	undef,
	$VERBOSITY,
	0,
	# 0, # less than expected
);
ok($@, "Image::DecodeQR::WeChat::detect_and_decode_qr_xs() : illegal calling with an array of 5 scalars caught (one less than expected).");

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
