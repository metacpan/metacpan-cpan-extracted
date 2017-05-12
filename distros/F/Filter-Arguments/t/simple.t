# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Filter-Arguments.t'

#########################

use strict;
use Test::More tests => 1;

my $scalar;

BEGIN {
	use_ok('Filter::Arguments');
};

$scalar = Argument;

my $noodles = Argument;

my $poodles = Argument( 'holey' => 'moley' );

my (
    $a,
    $b,
    $c,
) = Arguments( 
    alias => 'oink',
    default => 'milk',
);

my ($x,$y,$z) = ( Argument( x => 1 ), Argument( y => 2 ), Argument( z => 3 ) );

1;
