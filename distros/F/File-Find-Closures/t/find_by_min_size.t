# $Id$
use strict;

use File::Find            qw(find);
use File::Spec::Functions qw(curdir);

use vars qw( $expected_count $size );

BEGIN {
	$size           = 500;
	$expected_count = 0;
	
	find( sub { if( -s $_ >= $size) { return if $_ eq "."; $expected_count++ } }, 
		curdir() );

	}
	
use Test::More tests => 7 + $expected_count;

use_ok( "File::Find::Closures" );

ok( defined *File::Find::Closures::find_by_min_size{CODE}, 
	"file_by_name is defined" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
my( $finder, $reporter ) = File::Find::Closures::find_by_min_size( $size );
isa_ok( $finder,   'CODE' );
isa_ok( $reporter, 'CODE' );

find( $finder, curdir() );

my @files = $reporter->();

my $files = $reporter->();
isa_ok( $files, 'ARRAY', "Gets anonymous array in scalar context" );

is( scalar @files, $expected_count, 
	"Found right number [$expected_count] with less than $size bytes" );
foreach my $file ( @files )
	{
	my $this_size = -s $file;
	ok( $this_size >= $size, "$file is over $size bytes [$this_size]" );
	}

is( scalar @$files, $expected_count, "Found right number with less than $size bytes" );
