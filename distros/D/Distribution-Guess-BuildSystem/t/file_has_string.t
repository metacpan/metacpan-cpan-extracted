#!/usr/bin/perl
use strict;
use warnings;

use Test::More ;
use Test::Output;

use File::Spec;

my $class = 'Distribution::Guess::BuildSystem';

use_ok( $class );

can_ok( $class, '_file_has_string' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# These tests pass
{
my $pass_tests = {
	't/test-distros/makemaker-true/Makefile.PL'             => 'MakeMaker',
	't/test-distros/module-build-compat/Build.PL'           => 'create_makefile_pl',
	't/test-distros/module-install-autoinstall/Makefile.PL' => 'auto_install'
	};

foreach my $file ( sort keys %$pass_tests )
	{
	my $name = File::Spec->catfile( split m|/|, $file );
	ok( -e $name, "Passing file [$name] exists" );

	ok( $class->_file_has_string( $name, $pass_tests->{$file} ) );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# These tests fail because the right string is not in the file
{
my $fail_tests = {
	't/test-distros/makemaker-true/Makefile.PL'             => 'Build.PL',
	't/test-distros/module-build-compat/Build.PL'           => 'Buster',
	't/test-distros/module-install/Makefile.PL'             => 'auto_install'
	};

foreach my $file ( sort keys %$fail_tests )
	{
	my $name = File::Spec->catfile( split m|/|, $file );
	ok( -e $name, "Passing file [$name] exists" );

	ok( ! $class->_file_has_string( $name, $fail_tests->{$file} ) );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# These tests fail because the file is missing
{
stderr_like
	{ $class->_file_has_string( 'foo/bar/baz', 'Buster' ) }
	qr/not open/,
	"fails for non-existent file";
}

done_testing();
