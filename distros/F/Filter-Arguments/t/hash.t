# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Filter-Arguments.t'

#########################

use strict;
use Test::More tests => 5;

BEGIN {
	use_ok('Filter::Arguments');
};

my @ARGV = qw( a b c --boolean --one_value foo --multi_value one two three );

my %hash    = Argument( alias => 'alias' );
my $hash_rh = Argument( alias => 'alias' );

my %expect = (
    alias       => [ 'a', 'b', 'c' ],
    boolean     => 1,
    one_value   => 'foo',
    multi_value => [ 'one', 'two', 'three' ],
);

is_deeply( \%hash, \%expect, 'correct hash from arguments' );

is_deeply( $hash_rh, \%expect, 'correct hash ref from arguments' );

@ARGV = ();

%hash = Argument( '--hello' => 'world' );

%expect = ( 'hello' => 'world' );

is_deeply( \%hash, \%expect, 'correct hash alias and default' );

@ARGV = qw( --a --b --c --drink Jolt --eat Rice Beans --numbers 3 2 1 );

%hash = Arguments; # comment here -- no worries

%expect = (
   a       => 1,
   b       => 1,
   c       => 1,
   drink   => 'Jolt',
   eat     => [ 'Rice', 'Beans' ],
   numbers => [ 3, 2, 1 ],
);

is_deeply( \%hash, \%expect, 'correct hash from arguments' );

1;
