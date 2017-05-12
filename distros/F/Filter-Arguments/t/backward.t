# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Filter-Arguments.t'

#########################

use strict;
use Test::More tests => 18;

BEGIN {
	use_ok('Filter::Arguments');
};

@ARGV = qw( --solo --a --b --c --d A --e B --f C --x --y --z --six );

my $solo                : Argument(bool) = 1;
my $bool_default        : Argument;
my ($a,$b,$c)           : Arguments(bool);
my ($d,$e,$f)           : Arguments(value);
my ($x,$y,$z)           : Arguments(xbool);
my ($three,$four,$five) : Arguments(value) = (3,4,5);
my ($six,$seven,$eight) : Arguments(bool)  = ('SIX','SEVEN','EIGHT');

is( $solo, 1, 'bool solo backward compatible' );
is( $bool_default, undef, 'bool by default backward compatible' );
is( $a, 1, 'bool a backward compatible' );
is( $b, 1, 'bool b backward compatible' );
is( $c, 1, 'bool c backward compatible' );
is( $d, 'A', 'value d backward compatible' );
is( $e, 'B', 'value e backward compatible' );
is( $f, 'C', 'value f backward compatible' );
is( $x, 1, 'xbool x backward compatible' );
is( $y, 1, 'xbool y backward compatible' );
is( $z, 1, 'xbool z backward compatible' );
is( $three, 3, 'value three backward compatible' );
is( $four, 4, 'value four backward compatible' );
is( $five, 5, 'value five backward compatible' );
is( $six, '1', 'bool six backward compatible' );
is( $seven, 'SEVEN', 'bool seven backward compatible' );
is( $eight, 'EIGHT', 'bool eight backward compatible' );

1;
