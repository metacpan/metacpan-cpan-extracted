use strict;
use warnings;
use Test::More tests => 3;

use_ok('Math::Approx::Symbolic');

my $poly = sub {
    my ( $n, $x ) = @_;
    return $x**$n;
};

my %x;
for ( 1 .. 20 ) {
    $x{$_} = sin( $_ / 10 ) * cos( $_ / 30 ) + 0.3 * rand;
}

my $a = new Math::Approx::Symbolic( $poly, 5, %x );
ok( ref($a) eq 'Math::Approx::Symbolic' );

my $s = $a->symbolic();

ok( ref($s) eq 'Math::Symbolic::Operator' );

