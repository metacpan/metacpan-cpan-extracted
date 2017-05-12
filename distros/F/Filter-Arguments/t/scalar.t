# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Filter-Arguments.t'

#########################

use strict;
use Test::More tests => 10;

BEGIN {
	use_ok('Filter::Arguments');
};

my @ARGV = qw( --scalar --scalar_value foo --beeblebrox moley --a 3 2 1 --b --c );

my $scalar                         = Argument;
my $scalar_value                   = Argument;
my $scalar_aliased                 = Argument( alias => '--beeblebrox', default => 'xaphod' );
my $scalar_value_initialized       = Argument( default => 'bar' );
my ($scalar_a,$scalar_b,$scalar_c) = Argument( default => 'x' );
my $scalar_default                 = Argument( '--default' => 'default value' );
my ($a,$b,$c)                      = Arguments;

is( $scalar, 1, 'scalar boolan' );
is( $scalar_value, 'foo', 'scalar value' );
is( $scalar_aliased, 'moley', 'aliased scalar' );
is( $scalar_value_initialized, 'bar', 'default scalar value' );
is( $scalar_a, 'x', 'scalar list default value' );
is( $scalar_b, 'x', 'scalar list default value' );
is( $scalar_c, 'x', 'scalar list default value' );
is( $scalar_default, 'default value', 'string default' );
is( $a, 3, 'scalar accepts first value among several' );

1;
