#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use File::Basename;
use File::Spec;
use Cwd;

my $class = 'Distribution::Guess::BuildSystem';

my $test_file = basename( $0 );
(my $test_dir = $test_file ) =~ s/\.t$//;

my $test_distro_directory = File::Spec->catfile( 
	qw( t test-distros ), $test_dir 
	);

ok( -d $test_distro_directory, 
	"Test directory [$test_distro_directory] exists" 
	);

use_ok( $class );

my $guesser = $class->new(
	dist_dir => $test_distro_directory
	);
	
isa_ok( $guesser, $class );

can_ok( $guesser, 
	qw(
	makemaker_name makemaker_version make_command 
	makefile_pl	makefile_pl_path
	build_pl build_pl_path
	build_commands build_files build_file_paths
	preferred_build_file preferred_build_command
	) 
	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Should be Makefile.PL and Build.PL
{
my $filenames = $guesser->build_files;
isa_ok( $filenames, ref {} );
is( scalar keys %$filenames, 2, "Only one path from build_file_path" );
}

{
my $paths = $guesser->build_file_paths;
isa_ok( $paths, ref {} );
is( scalar keys %$paths, 2, "Only one path from build_file_path" );

is( $paths->{ $guesser->makefile_pl }, $guesser->makefile_pl_path, 
	'build_files_paths matches makefile_pl_path' );
}

{
my $hash = $guesser->build_commands;
isa_ok( $hash, ref {} );

is( scalar keys %$hash, 2, "There is only one hash key in build_commands" );

my @keys = sort keys %$hash;

ok( scalar grep { qr/\b[nd]?make(?:.exe)?\z/ } @keys, 'Uses a make variant' );
ok( scalar grep {   /perl/                   } @keys, 'Uses perl' );

# This Build.PL is a faker. It's just a wrapper around Makefile.PL,
# so it doesn't really use Build.PL
is( $guesser->preferred_build_file, $guesser->makefile_pl,
	"the preferred build file is a MakeMaker variant" );

is( $guesser->preferred_build_command, $guesser->make_command,
	"the preferred build command is a make variant" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# These should return true
{
my @pass_methods = qw(
	uses_makemaker has_makefile_pl
	has_build_pl has_build_and_makefile 	
	build_pl_wraps_makefile_pl
	);

can_ok( $class, @pass_methods );

foreach my $method ( @pass_methods )
	{
	ok( $guesser->$method(), "$method returns true (good)" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# These should return false
{
my @fail_methods = qw(
	uses_module_build_compat
	uses_module_install 
	uses_auto_install
	uses_module_build_only
	);

can_ok( $class, @fail_methods );

foreach my $method ( @fail_methods )
	{
	ok( ! $guesser->$method(), "$method returns false (good)" );
	}
}

1;
