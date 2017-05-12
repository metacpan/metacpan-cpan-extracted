use strict;

use File::Find            qw(find);
use File::Spec::Functions qw(curdir);
	
use Test::More 0.95;

use_ok( "File::Find::Closures" );

ok( defined *File::Find::Closures::find_regular_files{CODE}, 
	"find_regular_files is defined" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my @tuples = (
	[ qw(t    15) ],
	[ qw(lib   1) ],
	);

foreach my $tuple ( @tuples ) {
	subtest $tuple->[0] => sub {
		my( $dir, $expected_count ) = @$tuple;
	
		my( $finder, $reporter ) = File::Find::Closures::find_regular_files();
		isa_ok( $finder,   ref sub {} );
		isa_ok( $reporter, ref sub {} );
	
		find( $finder, $dir );
	
		my @files = $reporter->(); 
		#diag( "Found files @files" );
	
		my $files = $reporter->();
		isa_ok( $files, ref [], "[$tuple->[0]] Gets anonymous array in scalar context" );
	
		is( scalar  @files, $expected_count, "[$tuple->[0]] Found right number of regular files" );
		
		is( scalar @$files, $expected_count, "[$tuple->[0]] Found right number of regular files" );
		}
	}

done_testing();
