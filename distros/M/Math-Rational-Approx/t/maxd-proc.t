#!perl

use strict;
use warnings;

use Math::Rational::Approx 'maxD' ;

use Test::More;
use Math::Trig qw[ pi ];

my @inputs =
  (
 { x => pi ,     maxD => 10,  n => 22,  d => 7,   maxD0 => 5 },
 { x => pi ,     maxD => 120, n => 355, d => 113, maxD0 => 7 },
 { x => 0.0625 , maxD => 16,  n => 1,   d => 16,  maxD0 => 3 },
 { x => sqrt(2), maxD => 7,   n => 7,   d => 5,   maxD0 => 4 },
 { x => sqrt(2), maxD => 409, n => 577, d => 408, maxD0 => 7 },

  );

for my $input ( @inputs ) {

	subtest "x = $input->{x}; maxD = $input->{maxD}" => sub {

		my ( $n, $d ) = maxD( $input->{x}, $input->{maxD} );

		is $n, $input->{n}, "n";
		is $d, $input->{d}, "d";

		# test if multiple calls works
		return unless $input->{maxD} > 1;


		( $n, $d, my $bounds ) = maxD( $input->{x}, $input->{maxD0} );
		( $n, $d ) = maxD( $input->{x}, $input->{maxD}, $bounds );

		is $n, $input->{n}, "multiple; n";
		is $d, $input->{d}, "multiple; d";

	};

}


done_testing;


