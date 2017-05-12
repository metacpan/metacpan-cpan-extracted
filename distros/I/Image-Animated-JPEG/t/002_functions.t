#!perl

use strict;
use warnings;

use lib 'lib';
use Test::More tests => 4;
use Test::Deep;
# use Data::HexDump;
# use Data::Dumper;

use Image::Animated::JPEG;

my ($ref, $ref_back, $binary);

$ref = {
	version		=> 0,
	delay		=> 1,
	repeat		=> 17,
	parse_next	=> 33,
	'length'	=> 49,
	previous	=> 4,
	x_offset	=> 5,
	y_offset	=> 6,
	dispose_op	=> 1,
};

$binary = Image::Animated::JPEG::encode_ajpeg_data($ref, { debug => 0 });
$ref_back = Image::Animated::JPEG::decode_ajpeg_data($binary, { debug => 0 });

cmp_deeply(
	$ref_back,
	$ref,
	"test data roundtrip (low values)"
);

$ref = {
	version		=> 0,
	delay		=> 65535,
	repeat		=> 65535,
	parse_next	=> 65535,
	'length'	=> 65535,
	previous	=> 65535,
	x_offset	=> 65535,
	y_offset	=> 65535,
	dispose_op	=> 2,
};

$binary = Image::Animated::JPEG::encode_ajpeg_data($ref, { debug => 0 });
$ref_back = Image::Animated::JPEG::decode_ajpeg_data($binary, { debug => 0 });

cmp_deeply(
	$ref_back,
	$ref,
	"test data roundtrip (med/max values)"
);


$ref = {
	version		=> 0,
	delay		=> 4294967295,
	repeat		=> 65535,
	parse_next	=> 65535,
	'length'	=> 4294967295,
	previous	=> 4294967295,
	x_offset	=> 65535,
	y_offset	=> 65535,
	dispose_op	=> 2,
};

$binary = Image::Animated::JPEG::encode_ajpeg_data($ref, { debug => 0 });
$ref_back = Image::Animated::JPEG::decode_ajpeg_data($binary, { debug => 0 });
# print HexDump($binary);
# print Dumper($ref,$ref_back);
cmp_deeply(
	$ref_back,
	$ref,
	"test data roundtrip (max values)"
);


$ref = {
	version		=> 0,
	delay		=> 65,
	repeat		=> 0,
	parse_next	=> 1,
	'length'	=> 1500,
	previous	=> 1500,
	x_offset	=> 250,
	y_offset	=> 75,
	dispose_op	=> 0,
	metadata	=> {
		filename => 'foobar',
		number	 => 123,
		zero	 => 0,
		empty	 => '',
	},
};

$binary = Image::Animated::JPEG::encode_ajpeg_data($ref, { debug => 0 });
$ref_back = Image::Animated::JPEG::decode_ajpeg_data($binary, { debug => 0 });
# print HexDump($binary);
# print Dumper($ref,$ref_back);
cmp_deeply(
	$ref_back,
	$ref,
	"test data roundtrip (generic values + metadata)"
);

