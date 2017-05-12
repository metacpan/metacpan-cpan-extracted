#!/usr/bin/perl -w

# Basic tests of the Image::Delivery classes

# To help separate test data from config data, all pre-built data used to run
# the tests will be lowercase, and all object created during the tests
# will Be This Case
use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 'tests' => 49;

use HTML::Location  ();
use Image::Delivery ();
use Image::Delivery::Provider::File ();





#####################################################################
# Preparation

# The test path to use
my $good_dir = catdir( 't', 'data', '04_good' );
ok( -d $good_dir, 'Good test directory exists' );
ok( -w $good_dir, 'Good test directory is writable' );

# ... and one not to.
my $bad_dir  = catdir( 't', 'data', '04_bad' );
ok( ! -d $bad_dir, 'Bad test directory is not writable' );

# The derived location for the above
my $good_location = HTML::Location->new( $good_dir, 'http://good.site/path' );
isa_ok( $good_location, 'HTML::Location' );

my $bad_location = HTML::Location->new( $bad_dir, 'http://bad.site/path' );
isa_ok( $bad_location, 'HTML::Location' );

# Test images to use
my $image1 = catfile( 't', 'data', '03_image.gif' );
my $image2 = catfile( 't', 'data', '04_help.gif'  );
ok( (-f $image1 and -r $image1), 'Found usable test image 1' );
ok( (-f $image2 and -r $image2), 'Found usable test image 2' );

# Create a provider that is in the cache
my $good_provider = Image::Delivery::Provider::File->new( $image1 );
isa_ok( $good_provider, 'Image::Delivery::Provider' );

# Create a provider not in the cache
my $new_provider = Image::Delivery::Provider::File->new( $image2 );
isa_ok( $new_provider, 'Image::Delivery::Provider' );

# Standalone Transform Path (in the cache)
my $good_path = $good_provider->TransformPath;
isa_ok( $good_path, 'Digest::TransformPath' );

# Standaline Transform Path (not in the cache)
my $new_path = $new_provider->TransformPath;
isa_ok( $new_path, 'Digest::TransformPath' );





#####################################################################
# Test the Constructor

# No params or stupid params
is( Image::Delivery->new(), undef, '->new with no params returns undef' );
is( Image::Delivery->new( Location => undef ), undef, '->new with bad params returns undef' );
is( Image::Delivery->new( Location => 'foo' ), undef, '->new with bad params returns undef' );
is( Image::Delivery->new( Location => 'HTML::Location' ), undef, '->new with bad params returns undef' );

# Bad directory
is( Image::Delivery->new( Location => $bad_location ), undef, '->new with bad location returns undef' );

# Good directory
my $Delivery = Image::Delivery->new( Location => $good_location );
isa_ok( $Delivery, 'Image::Delivery' );

# Test the basic Accessors
isa_ok( $Delivery->Location, 'HTML::Location' );
is( $Delivery->Location->path, $good_dir, '->Location returns original location' );





#####################################################################
# Testing the main methods

# ->filename needs only a TransformPath
is( $Delivery->filename( $good_path ), '3/377f84afe0', '->filename(TransformPath) returns correct filename' );
is( $Delivery->filename( $good_provider ), '3/377f84afe0', '->filename(Provider) returns correct filename' );
is( $Delivery->filename( $new_path ), 'e/ee2067f1d7', '->filename(TransformPath) returns correct filename' );
is( $Delivery->filename( $new_provider ), 'e/ee2067f1d7', '->filename(Provider) returns correct filename' );

{ # ->exists will check for all of the extensions
my $Location = $Delivery->exists( $good_path );
isa_ok( $Location, 'HTML::Location' );
is( $Location->uri, 'http://good.site/path/3/377f84afe0.gif', '->exists(TransformPath) finds the correct existing file' );
is( $Location->path, 't/data/04_good/3/377f84afe0.gif', '->exists(TransformPath) finds the correct existing file' );
$Location = $Delivery->exists( $good_provider );
isa_ok( $Location, 'HTML::Location' );
is( $Location->uri, 'http://good.site/path/3/377f84afe0.gif', '->exists(TransformPath) finds the correct existing file' );
is( $Location->path, 't/data/04_good/3/377f84afe0.gif', '->exists(TransformPath) finds the correct existing file' );
}

{ # ->exists returns false ('') when it can't find the existing file
my $Location = $Delivery->exists( $new_path );
ok( (defined $Location and ! ref $Location), '->exists(TransformPath) returns defined and non-reference' );
is( $Location, '', '->exists(TransformPath) correctly finds no file' );
$Location = $Delivery->exists( $new_provider );
ok( (defined $Location and ! ref $Location), '->exists(TransformPath) returns defined and non-reference' );
is( $Location, '', '->exists(TransformPath) correctly finds no file' );
}

{ # ->get returns the existing data
my $data1 = $Delivery->get( $good_path );
my $data2 = $Delivery->get( $good_provider );
ok( $data1, '->get(TransformPath) returns the data' );
ok( ref $data1 eq 'SCALAR', '->get returns a scalar reference' );
is_deeply( $data1, $data2, '->get returns same same for TransformPath or Provider args' );

# Check against the provider's original
is_deeply( $data1, $good_provider->image, '->get returns data matching the provider\'s original' );
}

{ # ->set adds something to the cache
is( $Delivery->set( $new_path ), undef, '->set(TransformPath) return undef' );
my $Location = $Delivery->set( $new_provider );
isa_ok( $Location, 'HTML::Location' );
is( $Location->uri, 'http://good.site/path/e/ee2067f1d7.gif', '->set returns the expected URI' );
is( $Location->path, 't/data/04_good/e/ee2067f1d7.gif', '->set returns the expected path' );

# Does the written data match the source data?
is( File::Slurp::read_file($image2), File::Slurp::read_file($Location->path),
	'->set wrote data matching the source file' );

# Does it now returns as existing?
is_deeply( $Location, $Delivery->exists($new_provider), '->exists now returns true for the provider we ->set' );

# Can we read the data back in?
is_deeply( $Delivery->get($new_provider), $new_provider->image, '->get fetches image data that matches original data' );
}

END {
	# Make sure that ->set gets cleaned up after if not below
	foreach my $path (
		catfile( $good_dir, 'e', 'ee2067f1d7.gif' ),
		catdir(  $good_dir, 'e' ),
	) {
		File::Remove::remove \1, $path;
	}
}

{ # ->clear removes an image from the cache

# Remember where it was
my $Location = $Delivery->exists( $new_provider );
isa_ok( $Location, 'HTML::Location' );
ok( -f $Location->path, 'Double checking location exists' );

# Try to clear it
my $rv = $Delivery->clear( $new_provider );
is( $rv, 1, '->clear returns true' );

# Does ->exists return false now?
is_deeply( $Delivery->exists( $new_provider ), '', '->exists returns false after ->clear' );

# Confirm the file is actually gone
ok( ! -e $Location->path, 'File does appear to be actually gone' );
}

1;
	