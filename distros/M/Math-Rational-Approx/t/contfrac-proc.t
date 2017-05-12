#!perl

use strict;
use warnings;

use Math::Rational::Approx qw[ contfrac contfrac_nd ] ;

use Test::More;
use Math::Trig qw[ pi ];

my @inputs =
  (
 { x => pi ,     N => 4, n => 355, d => 113 },
 { x => 0.0625 , N => 2, n => 1,   d => 16 },
 { x => sqrt(2), N => 8, n => 577, d => 408 },

  );

for my $input ( @inputs ) {

	subtest "x = $input->{x}" => sub {

		my ( $terms, $resid ) = contfrac( $input->{x}, $input->{N} );


		my ( $n, $d ) = contfrac_nd( $terms );

		is $n, $input->{n}, "n";
		is $d, $input->{d}, "d";

		# test if multiple calls works
		return unless $input->{N} > 1;

		( $terms, $resid ) = contfrac( $input->{x}, $input->{N} - 1 );
		( $terms, $resid ) = contfrac( $resid, 1, $terms );

		( $n, $d ) = contfrac_nd( $terms );

		is $n, $input->{n}, "multiple; n";
		is $d, $input->{d}, "multiple; d";


	};

}


done_testing;


