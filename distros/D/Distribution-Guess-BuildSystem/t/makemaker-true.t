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
	makefile_pl makefile_pl_path
	build_commands build_files build_file_paths
	preferred_build_file preferred_build_command
	)
	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Should only find Makefile.PL
{
my $filenames = $guesser->build_files;
isa_ok( $filenames, ref {} );
is( scalar keys %$filenames, 1, "Only one path from build_file_path" );
}

{
my $paths = $guesser->build_file_paths;
isa_ok( $paths, ref {} );
is( scalar keys %$paths, 1, "Only one path from build_file_path" );

is( $paths->{ $guesser->makefile_pl }, $guesser->makefile_pl_path,
	'build_files_paths matches makefile_pl_path' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Should be Makefile.PL
like( $guesser->make_command,
	qr/\b[gnd]?make(?:.exe)?\z/,
	'Build command from %Config is make'
	);

is( $guesser->makefile_pl_path,
	File::Spec->catfile( $test_distro_directory, $guesser->makefile_pl ),
	"makefile_pl_path gets right path to test build file"
	);

{
my $hash = $guesser->build_commands;
isa_ok( $hash, ref {} );

is( scalar keys %$hash, 1, "There is only one hash key in build_commands" );

my @keys = keys %$hash;

like( $keys[0], qr/\b[gnd]?make(?:.exe)?\z/, 'Uses a make variant' );

is( $guesser->preferred_build_file, $guesser->makefile_pl,
	"the preferred build command is a make variant" );

is( $guesser->preferred_build_command, $guesser->make_command,
	"the preferred build command is a make variant" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# These should return true
{
my @pass_methods = qw(
	uses_makemaker has_makefile_pl makemaker_version makefile_pl_path
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
	has_build_pl has_build_and_makefile uses_module_build_compat
	uses_module_install uses_auto_install module_build_version
	module_install_version uses_module_build_only
	);

can_ok( $class, @fail_methods );

foreach my $method ( @fail_methods )
	{
	ok( ! $guesser->$method(), "$method returns false (good)" );
	}
}

1;
