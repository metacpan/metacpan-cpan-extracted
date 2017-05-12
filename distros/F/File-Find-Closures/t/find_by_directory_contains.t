# $Id$
use strict;

use File::Find            qw(find);
use File::Spec::Functions qw(curdir);
	
use Test::More tests => 12;

use_ok( "File::Find::Closures" );

ok( defined *File::Find::Closures::find_by_directory_contains{CODE}, 
	"find_by_directory_contains is defined" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my @tuples = (
	[ qw(Closures.pm 2) ],
	[ qw(ABC.pm      0) ],
	);

foreach my $tuple ( @tuples )
	{
	my( $filename, $expected_count ) = @$tuple;
	
	my( $finder, $reporter ) = File::Find::Closures::find_by_directory_contains( 
		$filename 
		);
	isa_ok( $finder,   ref sub {} );
	isa_ok( $reporter, ref sub {} );
	
	find( $finder, curdir() );
	
	my @dirs = $reporter->(); 
	# diag( "Found dirs @dirs" );
	
	my $dirs = $reporter->();
	isa_ok( $dirs, ref [], "Gets anonymous array in scalar context" );
	
	is( scalar  @dirs, $expected_count, "Found right number of $filename" );
		
	is( scalar @$dirs, $expected_count, "Found right number of $filename" );
	}

