#!/usr/bin/perl

# Load testing for File::PathList

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 43;
use File::Spec::Functions ':ALL';
use File::PathList ();

my @paths = (
	catfile( 't', 'data', 'foo' ),
	catfile( 't', 'data', 'bar' ),
	);
ok( -d $paths[0], 'Found first path dir'  );
ok( -d $paths[1], 'Found second path dir' );

my $file_txt = 'file.txt';
my $this_txt = 'this.txt';
my $bad_txt  = 'bad.txt';
my $deep     = 'deep';
my $deep_txt = catfile('deep', 'deep.txt');





#####################################################################
# Create some objects

SCOPE: {
	is( File::PathList->new(),             undef, '->new() returns undef' );
	is( File::PathList->new(undef),        undef, '->new(bad) returns undef' );
	is( File::PathList->new(''),           undef, '->new(bad) returns undef' );
	is( File::PathList->new('foo'),        undef, '->new(bad) returns undef' );
	is( File::PathList->new( cache => 1 ), undef, '->new(bad) returns undef' );
	
	my $object = File::PathList->new( \@paths );
	isa_ok( $object, 'File::PathList' );
	is_deeply( [ $object->paths ], \@paths, 'Returns the original paths' );
	is( $object->cache, '', '->cache returns false' );
	
	$object = File::PathList->new( paths => \@paths );
	isa_ok( $object, 'File::PathList' );
	is_deeply( [ $object->paths ], \@paths, 'Returns the original paths' );
	is( $object->cache, '', '->cache returns false' );
	
	$object = File::PathList->new( paths => \@paths, cache => undef );
	isa_ok( $object, 'File::PathList' );
	is_deeply( [ $object->paths ], \@paths, 'Returns the original paths' );
	is( $object->cache, '', '->cache returns false' );
	
	$object = File::PathList->new( paths => \@paths, cache => 1 );
	isa_ok( $object, 'File::PathList' );
	is_deeply( [ $object->paths ], \@paths, 'Returns the original paths' );
	is( $object->cache, 1, '->cache returns false' );
}





#####################################################################
# Test finding files

SCOPE: {
	my $front = File::PathList->new( [ @paths ] );
	my $back  = File::PathList->new( [ reverse @paths ] );
	
	# undef for bad files
	is( $front->find_file(),          undef, '->find_file(bad) returns undef' );
	is( $front->find_file(undef),     undef, '->find_file(bad) returns undef' );
	is( $front->find_file(''),        undef, '->find_file(bad) returns undef' );
	is( $front->find_file([]),        undef, '->find_file(bad) returns undef' );
	is( $front->find_file(\''),       undef, '->find_file(bad) returns undef' );
	is( $front->find_file({}),        undef, '->find_file(bad) returns undef' );
	is( $front->find_file(sub { 1 }), undef, '->find_file(bad) returns undef' );
	is( $front->find_file(bless({}, 'Foo')),
		undef, '->find_file(bad) returns undef' );
	is( $front->find_file( '/root' ), undef,
		'->find_file(root) returns undef' );
	is( $front->find_file( 'foo/../bar.txt'), undef,
		'->find_file(updir) returns undef' );
	
	# Find a file that only exists in one side
	is( $front->find_file($this_txt),
	    catfile( $paths[1], $this_txt ),
	    '->find_file finds expected file when exists in one' );
	is( $back->find_file($this_txt),
	    catfile( $paths[1], $this_txt ),
	    '->find_file finds expected file when exists in one' );
	
	# Find a file that exists in both sides
	is( $front->find_file($file_txt),
	    catfile( $paths[0], $file_txt ),
	    '->find_file finds expected file when exists in both' );
	is( $back->find_file($file_txt),
	    catfile( $paths[1], $file_txt ),
	    '->find_file finds expected file when exists in both' );
	
	# Find a file that doesn't exist
	is( $front->find_file( $bad_txt ), '', '->find_file(none) returns ""' );
	is( $back->find_file( $bad_txt ),  '', '->find_file(none) returns ""' );
	
	# Don't accidentally find a directory
	is( $front->find_file( $deep ), '', '->find_file(none) returns ""' );
	is( $front->find_file( $deep ), '', '->find_file(none) returns ""' );
	
	# Find a file in a subdir
	# Find a file that exists in both sides
	is( $front->find_file($deep_txt),
	    catfile( $paths[0], $deep_txt ),
	    '->find_file finds expected file when in a subdir' );
	is( $back->find_file($deep_txt),
	    catfile( $paths[0], $deep_txt ),
	    '->find_file finds expected file when in a subdir' );
}





#####################################################################
# Test the caching

SCOPE: {
	my $cache = File::PathList->new( paths => \@paths, cache => 1 );
	is( $cache->find_file($this_txt),
	    catfile( $paths[1], $this_txt ),
	    '->find_file finds expected file' );
	ok( exists $cache->{cache}->{$this_txt}, '->find_file created cache entry' );
	is( $cache->find_file($this_txt),
	    catfile( $paths[1], $this_txt ),
	    '->find_file finds expected file returns the same when cache entry exists' );
	$cache->{cache}->{$this_txt} = 'foo';
	is( $cache->find_file($this_txt),
	    'foo',
	    '->find_file finds returns the value from the cache' );
}
