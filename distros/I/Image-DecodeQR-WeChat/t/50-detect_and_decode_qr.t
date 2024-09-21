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
	:all
/;

# 0: nothing,
# > 9: add also XS verbose
my $VERBOSITY = 10;
my $GRAPHICAL_OUTPUT = 0;

# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = File::Temp::tempdir(CLEANUP=>1); # will not be erased if env var is set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my @testdata = (
	{
		# this is an empty one we expect nothing back but an empty arrayref
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'empty.jpg'),
		'outbase' => File::Spec->catdir($tmpdir, 'empty.out'),
		'expected-payloads' => [
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'test.jpg'),
		'outbase' => File::Spec->catdir($tmpdir, 'test.out'),
		'expected-payloads' => [
			'http://m.livedoor.com/'
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'test_rotated.jpg'),
		'outbase' => File::Spec->catdir($tmpdir, 'test_rotated.out'),
		'expected-payloads' => [
			'http://m.livedoor.com/'
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'japh.png'),
		'outbase' => File::Spec->catdir($tmpdir, 'japh.out'),
		'expected-payloads' => [
			'Just another Perl hacker'
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'τεστ.png'),
		'outbase' => File::Spec->catdir($tmpdir, 'τεστ.out'),
		'expected-payloads' => [
			"γειά σας είμαι ο Ανδρέας\n" # yes it has a newline
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'τεστ_rotated.png'),
		'outbase' => File::Spec->catdir($tmpdir, 'τεστ_rotated.out'),
		'expected-payloads' => [
			"γειά σας είμαι ο Ανδρέας\n" # yes it has a newline
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'complex_test.png'),
		'outbase' => File::Spec->catdir($tmpdir, 'complex_test.out'),
		'expected-payloads' => [
			# a collage of 4 QR codes as PNG
			"γειά σας είμαι ο Ανδρέας\n", # yes it has a newline
			"γειά σας είμαι ο Ανδρέας\n", # yes it has a newline
			'http://m.livedoor.com/',
			'http://m.livedoor.com/',
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'complex_test_lowquality.png'),
		'outbase' => File::Spec->catdir($tmpdir, 'complex_test_lowquality.out'),
		'expected-payloads' => [
			# a collage of 4 QR codes of lower quality as JPG
			"γειά σας είμαι ο Ανδρέας\n", # yes it has a newline
			'http://m.livedoor.com/',
			"γειά σας είμαι ο Ανδρέας\n", # yes it has a newline
			'http://m.livedoor.com/',
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'complex_test_rotated.png'),
		'outbase' => File::Spec->catdir($tmpdir, 'complex_test_rotated.out'),
		'expected-payloads' => [
			# a collage of 4 QR codes as PNG
			'http://m.livedoor.com/',
			'http://m.livedoor.com/',
			"γειά σας είμαι ο Ανδρέας\n", # yes it has a newline
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'complex_test_rotated_lowquality.jpg'),
		'outbase' => File::Spec->catdir($tmpdir, 'complex_test_rotated_lowquality.out'),
		'expected-payloads' => [
			# a collage of 4 QR codes of lower quality as JPG
			'http://m.livedoor.com/',
			'http://m.livedoor.com/',
			"γειά σας είμαι ο Ανδρέας\n", # yes it has a newline
		]
	},
);

# or by finding our share-dir and giving it to it
my $modelsdir = Image::DecodeQR::WeChat::modelsdir();
ok(-d $modelsdir, "models dir exists in '$modelsdir'") or BAIL_OUT("can not continue!");

my ($payloads, $bboxes, $ret);
for my $testdata (@testdata){
	my $testimg = $testdata->{'test-in-file'};
	my $expected = $testdata->{'expected-payloads'};
	my $num_expected = scalar @$expected;
	my $outbase = exists($testdata->{'outbase'})&&defined($testdata->{'outbase'}) ? $testdata->{'outbase'} : undef;
	my (@produced_files1, @produced_files2);
	if( $outbase ){
		@produced_files1 = map { $outbase.'.'.$_.'.jpg', $outbase.'.'.$_.'.xml' } (0..$#$expected);
		@produced_files2 = ($outbase.'.xml');
		unlink @produced_files1, @produced_files2;
	}

	ok(-f $testimg, "test image exists in '$testimg'.") or BAIL_OUT("can not continue!");

	$ret = Image::DecodeQR::WeChat::detect_and_decode_qr({
		# run it with minimal arguments to see if defaults kick in
		'input' => $testimg,
		'outbase' => $outbase,
		# don't test this now, we have another test for this
		'dumpqrimagestofile' => 0,
	});
	ok(defined($ret), "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and result is defined.");
	ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and result is of type ".ref($ret)." (expected: ARRAYref).");
	is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");
	($payloads, $bboxes) = @$ret;

	ok(defined($payloads), "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and payloads is defined.");
	ok(ref($payloads)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and payloads is ARRAYref.");
	is(scalar(@$payloads), $num_expected, "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and result contains ".scalar(@$payloads)." item exactly (expected: $num_expected).\n");

	ok(defined($bboxes), "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and bboxes is defined.");
	ok(ref($bboxes)eq'ARRAY', "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and bboxes is ARRAYref.");
	is(scalar(@$bboxes), $num_expected, "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and result contains ".scalar(@$bboxes)." item exactly (expected: $num_expected).\n");

	my @expe = (@$expected);
	for my $ap (@$payloads){
		my $found = 0;
		for my $idx (0..$#expe){
			if( $ap eq $expe[$idx] ){ $found = 1; splice(@expe, $idx, 1); last }
		}
		is($found, 1, "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and result payload '$ap' matches one of the expected: '".join("','", @$expected)."'.");
	}
	is(scalar(@expe), 0, "Image::DecodeQR::WeChat::detect_and_decode_qr() : called on '$testimg' and all result payloads were verified, nothing more nothing less (unseen payloads: ".scalar(@expe).").");

	if( $outbase && ($num_expected>0) ){
		# we don't expect any output files of this type, dumpi was 0
		ok(! -f $_, "Output file should not exist '$_'.") for @produced_files1;
		ok(-f $_, "Output file exists '$_'.") for @produced_files2;
		if( ! $VERBOSITY ){ unlink @produced_files2; }
	}
}

# make this to fail
$ret = Image::DecodeQR::WeChat::detect_and_decode_qr({});
ok(!defined($ret), "Image::DecodeQR::WeChat::detect_and_decode_qr() : called and result is not defined because parameters were wrong deliberately (return was: ".(defined($payloads)?perl2dump($payloads):"<undef>").").");

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
