#!/usr/bin/perl
use strict;
use warnings;

use vars qw( %stats $Ignore_value);

BEGIN {
	$Ignore_value = 0;

	%stats = (
		"Closures.pm"   => 3, # lib/Closures.pm blib/.../Closures.pm
		"test_manifest" => 4,
		"Makefile.PL"   => 5,
		"README.pod"    => 4, # ./README examples/README
		"Changes"       => 6,
		);

	# 13 because there are 13 elements in the list stat() returns
	*CORE::GLOBAL::stat = sub {
		return ( $stats{$_[0]} || $Ignore_value ) x 13;
		};
	}

use File::Find;
use Test::More tests => 28;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
is( ( stat('Foo.pm')      )[0], 0 );
is( ( stat('Closures.pm') )[0], 3 );

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
		#  method  value stat_part ignore_value
	[ qw( _find_by_stat_part_equal       3 4 2   0) ],
	[ qw( _find_by_stat_part_lessthan    5 4 5 999) ],
	[ qw( _find_by_stat_part_greaterthan 4 4 2   0) ],
	);

foreach my $tuple ( @tuples ) {
	no strict 'refs';

	my( $method, $value, $stat_part, $expected_count ) = @{$tuple}[0..3];

	# diag( "method is $method" );
	# diag( "stat is $stat_part" );

	$Ignore_value = $tuple->[-1];

	my( $wanted, $reporter ) =
		&{"File::Find::Closures::$method"}( $value, $stat_part );

	File::Find::find( $wanted, "." );

	my @files = $reporter->();
	# diag( "Found @files" );
	is( scalar @files, $expected_count, "$method: Found $expected_count files" );

	my $files = $reporter->();
	isa_ok( $files, ref [] );
	is( scalar @$files, $expected_count, "$method: Found $expected_count files" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my @tuples = (
	[ qw( find_by_created_after    3 5   0 ) ],
	[ qw( find_by_created_before   5 5 999 ) ],
	[ qw( find_by_modified_after   3 5   0 ) ],
	[ qw( find_by_modified_before  6 6 999 ) ],
	);

foreach my $tuple ( @tuples ) {
	no strict 'refs';

	my( $method, $value, $expected_count ) = @{$tuple}[0..2];

#	diag( "method is $method" );
#	diag( "stat is $stat_part" );

	$Ignore_value = $tuple->[-1];

	my( $wanted, $reporter ) =
		&{"File::Find::Closures::$method"}( $value );

	File::Find::find( $wanted, "." );

	my @files = $reporter->();
#	diag( "Found @files" );
	is( scalar @files, $expected_count, "$method: Found $expected_count files" );

	my $files = $reporter->();
	isa_ok( $files, ref [] );
	is( scalar @$files, $expected_count, "$method: Found $expected_count files" );
	}
}

__END__

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
find_by_owner
find_by_group
find_by_writeable
find_by_umask
find_by_executable
