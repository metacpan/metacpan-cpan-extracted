#!/usr/bin/perl -w

# Basic first pass API testing for PPI

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'lib') );
	}
}

# Execute the tests
use Test::More 'tests' => 42;
use Image::Delivery;
use Image::Delivery::Provider::Scalar;
use Image::Delivery::Provider::IOHandle;
use Image::Delivery::Provider::File;

# Execute the tests
use Test::ClassAPI;
Test::ClassAPI->execute('complete');
exit(0);

# Define the API
__DATA__
Image::Delivery=class
Image::Delivery::Provider=abstract
Image::Delivery::Provider::Scalar=class
Image::Delivery::Provider::IOHandle=class
Image::Delivery::Provider::File=class

[Image::Delivery]
new=method
Location=method
filename=method
exists=method
get=method
set=method
clear=method

[Image::Delivery::Provider]
filetypes=method
new=method
id=method
image=method
content_type=method
extension=method
TransformPath=method

[Image::Delivery::Provider::Scalar]
Image::Delivery::Provider=isa

[Image::Delivery::Provider::IOHandle]
Image::Delivery::Provider=isa

[Image::Delivery::Provider::File]
Image::Delivery::Provider=isa
