#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 26;
use Test::File::Cleaner   ();
use File::Spec::Functions ':ALL';
use Imager                ();
use Imager::Search        ();





#####################################################################
# Load the Test Files

# Create the file cleaner
my $cleaner = Test::File::Cleaner->new('t');

# Testing is done with bmp files, since that doesn't need external libs
my $small_file = catfile( 't', 'data', 'basic', 'small2.bmp' );
ok( -f $small_file, 'Found small file' );

my $small = Imager->new;
isa_ok( $small, 'Imager' );
ok( $small->read( file => $small_file ), '->open ok' );
is( $small->getchannels, 3, '->channels is 3' );
is( $small->bits, 8, '->bits is 8' );

# File for testing caching
my $cache = catfile( qw{ t data basic small.rgx } );
ok( ! -f $cache, 'Cache file does not exist' );





#####################################################################
# Test Pattern Construction

# Create a pattern object
my $lines1 = undef;
SCOPE: {
	my $pattern = Imager::Search::Pattern->new(
		driver => 'Imager::Search::Driver::HTML24',
		image  => $small,
	);
	isa_ok( $pattern, 'Imager::Search::Pattern' );
	isa_ok( $pattern->driver, 'Imager::Search::Driver' );
	isa_ok( $pattern->driver, 'Imager::Search::Driver::HTML24' );
	is( $pattern->file, undef, '->file returns null' );
	isa_ok( $pattern->image,  'Imager' );
	is( $pattern->height, 13, '->height ok' );
	is( $pattern->width, 13,  '->width ok' );
	my $lines2 = $pattern->lines;
	is( ref($lines2), 'ARRAY', '->lines ok' );
}

# Create the same thing from a file.
# Additionally, use the shorthand driver name
my $lines2 = undef;
SCOPE: {
	my $pattern = Imager::Search::Pattern->new(
		driver => 'HTML24',
		file   => $small_file,
	);
	isa_ok( $pattern, 'Imager::Search::Pattern' );
	isa_ok( $pattern->driver, 'Imager::Search::Driver' );
	isa_ok( $pattern->driver, 'Imager::Search::Driver::HTML24' );
	is( $pattern->file, $small_file, '->file returns null' );
	isa_ok( $pattern->image,  'Imager' );
	is( $pattern->height, 13, '->height ok' );
	is( $pattern->width, 13,  '->width ok' );
	my $lines2 = $pattern->lines;
	is( ref($lines2), 'ARRAY', '->lines ok' );
}

# Do they match regexp-wise?
is_deeply( $lines1, $lines2, '->lines match' );

# Create and write to a cache file
SCOPE: {
	my $pattern = Imager::Search::Pattern->new(
		driver => 'HTML24',
		file   => $small_file,
	);
	isa_ok( $pattern, 'Imager::Search::Pattern' );

	# Write to the cache file
	ok( $pattern->write($cache), '->write(file) ok' );

	# Does the file exist
	ok( -f $cache, 'Cache file was created' );
}
