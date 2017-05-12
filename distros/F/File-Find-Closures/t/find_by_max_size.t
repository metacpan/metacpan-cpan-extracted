# $Id$
use strict;

use File::Find            qw(find);
use File::Spec::Functions qw(curdir);

use vars qw( $expected_count $size );

BEGIN {
	$size           = 500;
	$expected_count = 0;
	
	find( sub { if( -s $_ <= $size) { return if $_ eq "."; $expected_count++ } }, 
		curdir() );

	}
	
use Test::More tests => 9 + $expected_count - 2;

use_ok( "File::Find::Closures" );

ok( defined *File::Find::Closures::find_by_max_size{CODE}, 
	"file_by_name is defined" );


my( $finder, $reporter ) = File::Find::Closures::find_by_max_size( $size );
isa_ok( $finder,   'CODE' );
isa_ok( $reporter, 'CODE' );

find( $finder, curdir() );

my @files = $reporter->();
my $files = $reporter->();
isa_ok( $files, 'ARRAY', "Gets anonymous array in scalar context" );

is( scalar @files, $expected_count, 
	"Found right number with more than $size bytes" );
foreach my $file ( @files )
	{
	ok( -s $file <= $size, "$file is under $size bytes" );
	}
	
#is( $files[0], '.cvsignore', "Found .cvsignore" );
is( scalar @$files, $expected_count, 
	"Found right number with more than $size bytes" );
#is( $files->[0], '.cvsignore', "Found .cvsignore" );
