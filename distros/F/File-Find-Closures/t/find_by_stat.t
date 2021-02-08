#!/usr/bin/perl
use strict;
use warnings;

use vars qw( %stats $Ignore_value);

BEGIN {
# Make fake stat records where a file has the same value in every slot.
# These functions don't care about the semantic meanigs of the numbers.
# It's all relative comparisons.

# The ignore_value is something you can adjust to move unlisted files
# outside the window of comparison. When you're looking for files that
# are greater than a value, $Ignore_value should be low. When you are
# looking for something that should be less than a value, $Ignore_value
# should be high.

	$Ignore_value = 0;

	%stats = (
		"Closures.pm"   => 3, # x 2 = lib/Closures.pm blib/.../Closures.pm
		"test_manifest" => 4,
		"Makefile.PL"   => 5,
		"MANIFEST"      => 4,
		"Changes"       => 6,
		);

	# 13 because there are 13 elements in the list stat() returns
	*CORE::GLOBAL::stat = sub {
		return ( $stats{$_[0]} || $Ignore_value ) x 13;
		};
	}

use Cwd qw(cwd);
use File::Find;
use File::Spec::Functions qw(abs2rel);
use Test::More tests => 28;

my $starting_dir = cwd();

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that the first stat value is right
is( ( stat('Foo.pm')      )[0], $Ignore_value, 'Overloaded stat.0 returns ignored value for missing file'  ); # ignore value
is( ( stat('Closures.pm') )[0], 3, 'Overloaded stat.0 returns configured value for existing file' );

my $count = () = stat( 'Bar.pm' );
is( $count, 13, "overloaded stat returns the right number of elements" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
use_ok( "File::Find::Closures" );

my @methods = qw(
	_find_by_stat_part_equal
	_find_by_stat_part_lessthan
	_find_by_stat_part_greaterthan
	);

foreach my $method ( @methods ) {
	no strict 'refs';
	ok( defined *{"File::Find::Closures::$method"}{CODE},
		"$method is defined" );
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my @tuples = (
		#  method  argument stat_part ignore_value
	[ qw( _find_by_stat_part_equal       3 4 2   0) ], # b?lib/.../Closures.pm
	[ qw( _find_by_stat_part_lessthan    5 4 4 999) ], # b?lib/.../Closures.pm test_manifest MANIFEST
	[ qw( _find_by_stat_part_greaterthan 4 4 2   0) ], # Makefile.PL Changes
	);

foreach my $tuple ( @tuples ) {
	no strict 'refs';

	my( $method, $value, $stat_part, $expected_count, $ignore ) = @{$tuple}[0..4];

	local $Ignore_value = $tuple->[-1];

	my( $wanted, $reporter ) =
		&{"File::Find::Closures::$method"}( $value, $stat_part );

	# Perl v5.8 on Travis would end up in / after the first find()
	# I don't know why but instead of relying on . I saved the starting
	# directory at the beginning of the program.
	File::Find::find( $wanted, $starting_dir );

	my @files = map { abs2rel( $_, $starting_dir ) } @{ $reporter->() };
	diag( "comparison loop for $method: Found @files" );
	is( scalar @files, $expected_count, "$method (list context): Found $expected_count files for stat.$stat_part with value $value" );

	my $files = $reporter->();
	isa_ok( $files, ref [] );
	is( scalar @$files, $expected_count, "$method (scalar context): Found $expected_count files" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my @tuples = (
	# method time_value expected_count ignore_value
	[ qw( find_by_created_after    3 4   0 ) ],
	[ qw( find_by_created_before   5 4 999 ) ],
	[ qw( find_by_modified_after   3 4   0 ) ],
	[ qw( find_by_modified_before  6 5 999 ) ],
	);

foreach my $tuple ( @tuples ) {
	no strict 'refs';

	my( $method, $time_value, $expected_count ) = @{$tuple}[0..2];

	local $Ignore_value = $tuple->[-1];

	my( $wanted, $reporter ) =
		&{"File::Find::Closures::$method"}( $time_value );

	File::Find::find( $wanted, $starting_dir );

	my @files = map { abs2rel( $_, $starting_dir ) } @{ $reporter->() };
	diag( "relative loop: Found @files" );
	is( scalar @files, $expected_count, "$method (list context): Found $expected_count files with time value $time_value" );

	my $files = $reporter->();
	isa_ok( $files, ref [] );
	is( scalar @$files, $expected_count, "$method (scalar context): Found $expected_count files with time value $time_value" );
	}
}

__END__
