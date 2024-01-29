use strict;

use File::Basename        qw(basename);
use File::Find            qw(find);
use File::Spec::Functions qw(catfile curdir canonpath);

use Test::More;

my @t_files = glob( 't/*.t' );
my $t_file_count = @t_files;

subtest sanity => sub {
	use_ok( "File::Find::Closures" );
	can_ok( "File::Find::Closures", "find_by_extension" );
	};

subtest pm => sub {
	extension_find( [ qw(lib) ], [ qw(pm) ], 1 )
	};

subtest t => sub {
	extension_find( [ qw(t) ], [ qw(t) ], $t_file_count )
	};

subtest dot_t => sub {
	extension_find( [ qw(t) ], [ qw(t) ], $t_file_count )
	};

subtest find_both => sub {
	extension_find( [ qw(t lib) ], [ qw(t pm) ], 1 + $t_file_count )
	};

subtest find_nothing => sub {
	# ensure we don't find things that aren't file extensions
	extension_find( [ qw(.) ], [ qw(est) ], 0 )
	};

sub extension_find {
	my( $starting_dir, $extensions, $expected_count ) = @_;

	my( $finder, $reporter )
		= File::Find::Closures::find_by_extension(@$extensions);
	isa_ok( $finder,   'CODE' );
	isa_ok( $reporter, 'CODE' );

	find( $finder, @$starting_dir );

	my @files = $reporter->();
	my $files = $reporter->();
	isa_ok( $files, 'ARRAY', "Gets anonymous array in scalar context" );

	is( scalar @files,  $expected_count, "found $expected_count files" );
	is( scalar @$files, $expected_count, "found $expected_count files" );
	}

done_testing();
