# $Id$
use strict;

use File::Basename        qw(basename);
use File::Find            qw(find);
use File::Spec::Functions qw(catfile curdir canonpath);

use Test::More tests => 12;

use_ok( "File::Find::Closures" );

ok( defined *File::Find::Closures::find_by_name{CODE}, 
	"file_by_name is defined" );

foreach my $file ( qw(MANIFEST t/compile.t) )
	{
	my $name  = basename( $file );

	my $expected = 0;
	find( sub { $expected++ if $_ eq $name }, curdir() );
	#diag( "Expected is $expected" );
	
	my $base  = curdir();
	my $path  = catfile( $base, split '/', $file );
	my $canon = canonpath( $path ); # catfile should do this
	
	my( $finder, $reporter ) = File::Find::Closures::find_by_name( $name );
	isa_ok( $finder,   'CODE' );
	isa_ok( $reporter, 'CODE' );
	
	find( $finder, $base );
	
	my @files = $reporter->();
	my $files = $reporter->();
	isa_ok( $files, 'ARRAY', "Gets anonymous array in scalar context" );
	
	is( scalar @files, $expected, "Found one file looking for $name" );
	#is( $files[0], $canon, "Found $name" );

	is( scalar @$files, $expected, "Found one file looking for $name" );
	#is( $files->[0], $canon, "Found $name" );
	}