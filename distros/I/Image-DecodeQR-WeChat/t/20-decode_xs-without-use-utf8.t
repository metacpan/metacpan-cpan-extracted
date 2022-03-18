use strict;
use warnings;

our $VERSION = '0.8';

# this is an exact copy of t/01-decode.t but assuming that we did not
# use utf8
# the only difference to compensate for this is 
#   my $ut = utf8::is_utf8($ap) ? Encode::encode_utf8($ap) : $ap;

#use utf8; # allow for utf8 in code (we have strings in utf8, filenames)

use Test::More;

use Image::DecodeQR::WeChat;
use Encode;
use File::Spec;
use File::ShareDir qw/dist_dir/;
use FindBin;

#binmode(STDOUT, ':encoding(utf8)');
#binmode(STDERR, ':encoding(utf8)');

# 0: nothing,
# > 9: add also XS verbose
my $VERBOSITY = 10;
my $GRAPHICAL_OUTPUT = 0;
my $DUMP_IMAGES_AND_DATA_TO_FILES = 1;
my @testdata = (
	{
		# this is an empty one we expect nothing back but an empty arrayref
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'empty.jpg'),
		'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'empty.out'),
		'expected-payloads' => [
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'test.jpg'),
		'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'test.out'),
		'expected-payloads' => [
			'http://m.livedoor.com/'
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'test_rotated.jpg'),
		'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'test_rotated.out'),
		'expected-payloads' => [
			'http://m.livedoor.com/'
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'japh.png'),
		'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'japh.out'),
		'expected-payloads' => [
			'Just another Perl hacker'
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'τεστ.png'),
		'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'τεστ.out'),
		'expected-payloads' => [
			"γειά σας είμαι ο Ανδρέας\n" # yes it has a newline
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'τεστ_rotated.png'),
		'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'τεστ_rotated.out'),
		'expected-payloads' => [
			"γειά σας είμαι ο Ανδρέας\n" # yes it has a newline
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'complex_test.png'),
		'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'complex_test.out'),
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
		'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'complex_test_lowquality.out'),
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
		'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'complex_test_rotated.out'),
		'expected-payloads' => [
			# a collage of 4 QR codes as PNG
			'http://m.livedoor.com/',
			'http://m.livedoor.com/',
			"γειά σας είμαι ο Ανδρέας\n", # yes it has a newline
		]
	},
	{
		'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'complex_test_rotated_lowquality.jpg'),
		'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'complex_test_rotated_lowquality.out'),
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

my ($ret, $payloads, $bboxes);

for my $testdata (@testdata){
	my $testimg = $testdata->{'test-in-file'};
	my $expected = $testdata->{'expected-payloads'};
	my $num_expected = scalar @$expected;
	my $outbase = exists($testdata->{'outbase'})&&defined($testdata->{'outbase'}) ? $testdata->{'outbase'} : undef;
	my (@produced_files1, @produced_files2);
	if( $outbase ){
		@produced_files1 = map { $outbase.'.'.$_.'.png', $outbase.'.'.$_.'.txt' } (0..$#$expected);
		@produced_files2 = ($outbase.'.txt');
		unlink @produced_files1, @produced_files2;
	}

	ok(-f $testimg, "test image exists in '$testimg'.") or BAIL_OUT("can not continue!");

	$ret = Image::DecodeQR::WeChat::decode_xs(
		# this should not be needed ...
		#    Encode::encode_utf8($testimg),
		$testimg,
		$modelsdir,
		$outbase,
		$VERBOSITY,
		$GRAPHICAL_OUTPUT,
		$DUMP_IMAGES_AND_DATA_TO_FILES
	);
	ok(defined($ret), "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result is defined.");
	ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result is of type ".ref($ret)." (expected: ARRAYref).");
	is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");
	($payloads, $bboxes) = @$ret;

	ok(defined($payloads), "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and payloads is defined.");
	ok(ref($payloads)eq'ARRAY', "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and payloads is ARRAYref.");
	is(scalar(@$payloads), $num_expected, "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result contains ".scalar(@$payloads)." item exactly (expected: $num_expected).\n");

	ok(defined($bboxes), "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and bboxes is defined.");
	ok(ref($bboxes)eq'ARRAY', "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and bboxes is ARRAYref.");
	is(scalar(@$bboxes), $num_expected, "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result contains ".scalar(@$bboxes)." item exactly (expected: $num_expected).\n");

	my @expe = (@$expected);
	for my $ap (@$payloads){
		my $found = 0;
		for my $idx (0..$#expe){
			# 1: this is the only change if user forgets 'use utf8'
			my $ut = utf8::is_utf8($ap) ? Encode::encode_utf8($ap) : $ap;
			if( $ut eq $expe[$idx] ){ $found = 1; splice(@expe, $idx, 1); last }
		}
		is($found, 1, "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result payload '$ap' matches one of the expected: '".join("','", @$expected)."'.");
	}
	is(scalar(@expe), 0, "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and all result payloads were verified, nothing more nothing less (unseen payloads: ".scalar(@expe).").");

	if( $outbase && ($num_expected > 0) ){
		# check if any output files were produced depends on whether outbase was specified etc.
		if( $DUMP_IMAGES_AND_DATA_TO_FILES > 0 ){
			ok(-f $_, "Output file exists '$_'.") for @produced_files1;
			if( ! $VERBOSITY ){ unlink @produced_files1; }
		}
		ok(-f $_, "Output file exists '$_'.") for @produced_files2;
		if( ! $VERBOSITY ){ unlink @produced_files2; }
	}
}

# make this to fail
$ret = Image::DecodeQR::WeChat::decode_xs(
	'non-existent-image.chchchch',
	'non-existent-dir.agagagha',
	'non-existent-dir.chchchch',
	$VERBOSITY,
	$GRAPHICAL_OUTPUT,
	$DUMP_IMAGES_AND_DATA_TO_FILES
);
ok(!defined($ret), "Image::DecodeQR::WeChat::decode_xs() : called and result is not defined because parameters were wrong deliberately (return was: ".(defined($payloads)?$payloads:"<undef>").").");

done_testing;
