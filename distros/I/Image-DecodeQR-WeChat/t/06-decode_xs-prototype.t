use strict;
use warnings;

our $VERSION = '1.0';

use utf8; # allow for utf8 in code (we have strings in utf8, filenames)

use Test::More;
use Test2::Plugin::UTF8;

use Image::DecodeQR::WeChat;
use File::Spec;
use FindBin;

binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

# This checks calling decode_xs with 6 scalars (correct)
# array of 6 scalars (should be correct),
# 7 scalars (wrong, must be caught)
# array of 7 scalars (wrong, must be caught)
# after realising that as it is it complains
# when an array of 6 scalars is passed to decode_xs()
# To fix it to accept also array I have added
#   PROTOTYPE: @
# in XS code. (Note: it already had PROTOTYPES: ENABLE)

# 0: nothing,
# > 9: add also XS verbose
my $VERBOSITY = 10;
my $GRAPHICAL_OUTPUT = 0;
my $DUMP_IMAGES_AND_DATA_TO_FILES = 1;
my $testdata = {
	'test-in-file' => File::Spec->catdir($FindBin::Bin, 'testimages', 'japh.png'),
	'outbase' => File::Spec->catdir($FindBin::Bin, 'tmp', 'japh.out'),
	'expected-payloads' => [
		'Just another Perl hacker'
	]
};

# or by finding our share-dir and giving it to it
my $modelsdir = Image::DecodeQR::WeChat::modelsdir();
ok(-d $modelsdir, "models dir exists in '$modelsdir'") or BAIL_OUT("can not continue!");

my ($ret, $payloads, $bboxes);

my $testimg = $testdata->{'test-in-file'};
my $expected = $testdata->{'expected-payloads'};
my $num_expected = scalar @$expected;
my $outbase = exists($testdata->{'outbase'})&&defined($testdata->{'outbase'}) ? $testdata->{'outbase'} : undef;

ok(-f $testimg, "test image exists in '$testimg'.") or BAIL_OUT("can not continue!");

# call it with 6 scalars
$ret = Image::DecodeQR::WeChat::decode_xs(
	$testimg,
	$modelsdir,
	undef,
	$VERBOSITY,
	0,
	0
);
ok(defined($ret), "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");

# call it with an array of 6 scalars
my @params = (
	$testimg,
	$modelsdir,
	undef,
	$VERBOSITY,
	0,
	0
);
$ret = Image::DecodeQR::WeChat::decode_xs(@params);
ok(defined($ret), "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");

# call it with 1 scalar and an array of 5 scalars (as expected)
@params = (
	$modelsdir,
	undef,
	$VERBOSITY,
	0,
	0
);
$ret = Image::DecodeQR::WeChat::decode_xs($testimg, @params);
ok(defined($ret), "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");

# call it with 1 scalar and an array of 5 scalars (as expected)
@params = (
	$testimg,
	$modelsdir,
	undef,
	$VERBOSITY,
	0
);
$ret = Image::DecodeQR::WeChat::decode_xs(@params, 0);
ok(defined($ret), "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result is defined.");
ok(ref($ret)eq'ARRAY', "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result is of type ".ref($ret)." (expected: ARRAYref).");
is(scalar(@$ret), 2, "Image::DecodeQR::WeChat::decode_xs() : called on '$testimg' and result contains ".scalar(@$ret)." item exactly (expected: 2).\n");

#######
### these should all fail
#######

# call it with 7 scalars (one more than expected) - it should fail
$ret = eval {
	Image::DecodeQR::WeChat::decode_xs(
		$testimg,
		$modelsdir,
		undef,
		$VERBOSITY,
		0,
		0,
		1000 # one more params than expected
	)
};
ok($@, "Image::DecodeQR::WeChat::decode_xs() : illegal calling with 7 scalars caught (one more than expected).");

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
ok($@, "Image::DecodeQR::WeChat::decode_xs() : illegal calling with an array of 7 scalars caught (one more than expected).");

# call it with 5 scalars (one less than expected) - it should fail
$ret = eval {
	Image::DecodeQR::WeChat::decode_xs(
		$testimg,
		$modelsdir,
		undef,
		$VERBOSITY,
		0,
		# 0 # less than expected
	)
};
ok($@, "Image::DecodeQR::WeChat::decode_xs() : illegal calling with 5 scalars caught (one less than expected).");

# call it with an array of 5 scalars (one less than expected)
@params = (
	$testimg,
	$modelsdir,
	undef,
	$VERBOSITY,
	0,
	# 0, # less than expected
);
ok($@, "Image::DecodeQR::WeChat::decode_xs() : illegal calling with an array of 5 scalars caught (one less than expected).");

done_testing;
