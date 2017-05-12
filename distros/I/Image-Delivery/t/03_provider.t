#!/usr/bin/perl -w

# Basic tests of the Provider classes

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
}

use Test::More 'tests' => 52;

use IO::File                        ();
use Image::Delivery                 ();
use Image::Delivery::Provider::File ();

my $file = catfile('t', 'data', '03_image.gif');

ok( -f $file, 'Found test file' );
ok( -r $file, 'Permission to read test file' );

sub is_provider {
	my $Provider = shift;
	isa_ok($Provider, 'Image::Delivery::Provider' );
	my $methods = shift;
	ok( ref $methods eq 'HASH', 'Passed proper test arguments' );

	SKIP: {
		my $tests = keys %$methods;
		$tests++ unless $methods->{TransformPath};
		$tests++ unless $methods->{image};
		isa(ref $Provider, 'Image::Delivery::Provider')
			or skip "Did not get Provider, skipping methods tests", $tests;

		unless ( exists $methods->{image} ) {
			ok( ref $Provider->image eq 'SCALAR', '->image returns a SCALAR ref' );
		}
		unless ( exists $methods->{TransformPath} ) {
			isa_ok( $Provider->TransformPath, 'Digest::TransformPath' );
		}
		foreach my $method ( qw{id image content_type extension TransformPath} ) {
			if ( exists $methods->{$method} ) {
				is( $Provider->$method(), $methods->{$method}, "->$method matches expected" );
			}
		}
	}
}





#####################################################################
# Construction

# Do a basic check of a single file
is_provider( Image::Delivery::Provider::File->new( $file ), {
	id           => '20f86007b56d0e6b57a873124d79fe59',
	content_type => 'image/gif',
	extension    => 'gif',
	} );
is_provider( Image::Delivery::Provider::File->new( $file,
	id => 'foo',
	), {
	id           => 'foo',
	content_type => 'image/gif',
	extension    => 'gif',
	} );
is_provider( Image::Delivery::Provider::File->new( $file,
	content_type => 'image/png',
	), {
	id           => '20f86007b56d0e6b57a873124d79fe59',
	content_type => 'image/png',
	extension    => 'png',
	} );
is_provider( Image::Delivery::Provider::File->new( $file,
	extension    => 'png',
	), {
	id           => '20f86007b56d0e6b57a873124d79fe59',
	content_type => 'image/gif',
	extension    => 'png',
	} );

# Same thing, but with IOHandle
is_provider( Image::Delivery::Provider::File->new(IO::File->new($file)), {
	id           => '20f86007b56d0e6b57a873124d79fe59',
	content_type => 'image/gif',
	extension    => 'gif',
	} );

# Do the first again to catch a regression
is_provider( Image::Delivery::Provider::File->new( $file ), {
	id           => '20f86007b56d0e6b57a873124d79fe59',
	content_type => 'image/gif',
	extension    => 'gif',
	} );




#####################################################################
# Fetching data

my $Provider = Image::Delivery::Provider::File->new( $file );
isa_ok( $Provider, 'Image::Delivery::Provider' );
my $data1 = $Provider->image;
ok( $data1, '->image returns true' );
ok( ref $data1 eq 'SCALAR', '->image returns a scalar reference' );
is( length($$data1), 183, '->image returns data of the correct length' );

my $Provider2 = Image::Delivery::Provider::File->new(IO::File->new($file));
isa_ok( $Provider2, 'Image::Delivery::Provider' );
my $data2 = $Provider2->image;
ok( $data2, '->image returns true' );
ok( ref $data2 eq 'SCALAR', '->image returns a scalar reference' );
is( $$data1, $$data2, '->image via two different channels matches' );

1;
