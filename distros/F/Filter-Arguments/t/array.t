# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Filter-Arguments.t'

#########################

use strict;
use Test::More tests => 9;

BEGIN {
	use_ok('Filter::Arguments');
};

my @ARGV = qw( --array --array_one_value foo --array_multi_value one two three --beeblebrox a b c );

my @array                   = Argument;
my @array_one_value         = Argument;
my @array_multi_value       = Argument;
my @array_aliased           = Argument( alias => '--beeblebrox' );
my @array_value_initialized = Argument( default => [ 'foo','bar' ] );
my $array_ra                = Argument( alias => '--ref', default => [ 'foo','bar' ] );
my $array_multi_value_ra    = Argument;
my @array_default           = Argument( '--default' => [ 'default', 'values' ] );

is_deeply( \@array, [], 'no array values' );
is_deeply( \@array_one_value, [ 'foo' ], 'one array value' );
is_deeply( \@array_multi_value, [ 'one','two','three' ], 'multiple array values' );
is_deeply( \@array_aliased, [ 'a','b','c' ], 'aliased array' );
is_deeply( \@array_value_initialized, [ 'foo','bar' ], 'default multiple array values' );
is_deeply( $array_ra, [ 'foo','bar' ], 'default multiple aliased array ref values' );
is_deeply( $array_multi_value_ra, [ 'one','two','three' ], 'multiple array ref values' );
is_deeply( \@array_default, [ 'default', 'values' ], 'alias and default' );

1;
