#!perl

use strict;
use warnings;

use lib 'lib';
use Test::More tests => 18;
use Test::Deep;
# use Data::HexDump;
# use Data::Dumper;

use Image::Animated::JPEG;

## index()
{
	# non JPEG data
	open(my $io_file, '<', 't/data/files.nfo') or die $!;
	binmode($io_file);
	my $test = eval { Image::Animated::JPEG::index($io_file) };
	like($@, qr/^Does not look like a JPEG file: SOI missing at start of file/, 'indexing non-JPEG file fails');
}

{
	# normal JPEG file
	open(my $io_file, '<', 't/data/frame1.jpg') or die $!;
	binmode($io_file);
	my $test = eval { Image::Animated::JPEG::index($io_file) };
	is( scalar(@$test), 1, 'indexing normal JPEG file returns 1 frame');
	ok($test->[0]->{offset} == 0 && $test->[0]->{length} == 376, 'indexing normal JPEG file: frame properties ok');
}

{
	# simple AJPEG file
	open(my $io_file, '<', 't/data/frames_empty-marker.ajpeg') or die $!;
	binmode($io_file);
	my $test = eval { Image::Animated::JPEG::index($io_file) };
	# use Data::Dumper;
	# print Dumper($test);
	is( scalar(@$test), 3, 'indexing AJPEG file returns 3 frames');
	ok($test->[0]->{offset} == 0 && $test->[0]->{length} == 387, 'indexing AJPEG file: frame 1 properties ok');
	ok($test->[1]->{offset} == 387 && $test->[1]->{length} == 638, 'indexing AJPEG file: frame 2 properties ok');
	ok($test->[2]->{offset} == 1025 && $test->[2]->{length} == 386, 'indexing AJPEG file: frame 3 properties ok');
}

{
	# non AJPEG with JPEG thumbnail embedded
	open(my $io_file, '<', 't/data/frame1.jpg') or die $!;
	binmode($io_file);
	my $test = eval { Image::Animated::JPEG::index($io_file) };
	is( scalar(@$test), 1, 'indexing non-AJPEG file with JPEG thumb returns 1 frame');
	ok($test->[0]->{offset} == 0 && $test->[0]->{length} == 376, 'indexing non-AJPEG file with JPEG thumb: frame properties ok');
}


## process()
{
	# non JPEG data
	my $data = 123456;
	my $test = eval { Image::Animated::JPEG::process(\$data) };
	ok( $@ && $@ =~ /^Does not look like a JPEG file: SOI missing/, 'processing non-JPEG data fails');
}

{
	# wrong path
	my $test = eval { Image::Animated::JPEG::process('t/data/wrong_test0-fuji.jpg') };
	ok( $@ && $@ =~ /^Error opening file for reading: /, 'calling process with non-existent path fails');
}

{
	# find APP0 JFIF marker
	my $ref = Image::Animated::JPEG::process('t/data/test0-fuji.jpg');

	ok( keys(%$ref) == 1, 'process returns one APP0 marker (test0-fuji.jpg)');
	cmp_deeply(
		$ref,
		{
			'JFIF' => {
				'type'	 => 'APP0',
				'offset' => 2,
				'length' => 16,
				'data_offset' => 11,
				'data_length' => 9,
			}
		},
		"process returns hashref as expected (test0-fuji.jpg)"
	);
}

{
	# find APP0 AJPEG marker
	my $ref = Image::Animated::JPEG::process('t/data/frames_empty-marker.ajpeg');

	ok( keys(%$ref) == 2, 'process returns two APP0 markers (frames_empty-marker.ajpeg)');
	cmp_deeply(
		$ref,
		{
			'JFIF' => {
				'type'	 => 'APP0',
				'offset' => 2,
				'length' => 16,
				'data_offset' => 11,
				'data_length' => 9,
			},
			'AJPEG' => {
				'type'		=> 'APP0',
				'offset'	=> 20,
				'length'	=> 9,
				'data_offset'	=> 30,
				'data_length'	=> 1, # it's an empty marker, only version (one byte)

                     }
		},
		"process returns hashref as expected (frames_empty-marker.ajpeg)"
	);
	# use Data::Dumper;
	# print Dumper($ref);
}

{
	# find APP0 AJPEG marker, scalar ref, then decode and check values
	open(my $fh, "<", 't/data/frames_delay77.ajpeg') or die "Error opening file for reading 'frames_delay77.ajpeg': $!";
	binmode($fh);
	local $/;
	my $buffer = <$fh>; 
	close($fh);

	is( length($buffer), 1413, 'opening/slurping test-file (frames_delay77.ajpeg)');

	my $ref = Image::Animated::JPEG::process(\$buffer);
	cmp_deeply(
		$ref,
		{
			'JFIF' => {
				'type' => 'APP0',
				'offset' => 2,
				'length' => 16,
				'data_offset' => 11,
				'data_length' => 9
			},
			'AJPEG' => {
				'type' => 'APP0',
				'offset' => 20,
				'length' => 11,
				'data_offset' => 30,
				'data_length' => 3
			}
		},
		"process returns hashref as expected (frames_empty-marker.ajpeg)"
	);

	my $meta = Image::Animated::JPEG::decode_ajpeg_data( substr($buffer,$ref->{AJPEG}->{data_offset},$ref->{AJPEG}->{data_length}), { debug => 0 });
	cmp_deeply(
		$meta,
		{
			delay	=> 77,
			version => 0,
		},
		"extract AJPEG marker properties, from in-memory JPEG (frames_delay77.ajpeg)"
	);
	# use Data::Dumper;
	# print Dumper($meta);
}
