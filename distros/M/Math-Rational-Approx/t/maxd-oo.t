#!perl

use strict;
use warnings;

use Math::Rational::Approx::MaxD;

use Test::More;
use Math::Trig qw[ pi ];

my @inputs =
  (
 { x => pi ,     maxD => 10,  n => 22,  d => 7,
                 maxD0 => 5, n0 => 3,  d0 => 1 },

 { x => pi ,     maxD => 120, n => 355, d => 113,
                 maxD0 => 7, n0 => 22, d0 => 7 },

 { x => 0.0625 , maxD => 16,  n => 1,   d => 16,
                 maxD0 => 3, n0 => 0,   d0 => 1 },

 { x => sqrt(2), maxD => 7,   n => 7,   d => 5,
                 maxD0 => 4, n0 => 3,  d0 => 2  },

 { x => sqrt(2), maxD => 409, n => 577, d => 408,
                 maxD0 => 7, n0 => 7,  d0 => 5 },

  );

for my $input ( @inputs ) {

	subtest "x = $input->{x}; maxD = $input->{maxD}" => sub {

		my ($n, $d) = Math::Rational::Approx::MaxD->new( x => $input->{x},
		                                           maxD => $input->{maxD} )->approx;

		is $n, $input->{n}, "n";
		is $d, $input->{d}, "d";

		# test if multiple calls works
		return unless $input->{maxD} > 1;

		my $obj = Math::Rational::Approx::MaxD->new( x => $input->{x},
		                                             maxD => $input->{maxD0} );
		( $n, $d ) = $obj->approx;
		is $n, $input->{n0}, "multiple; n0";
		is $d, $input->{d0}, "multiple; d0";

		my $bounds = $obj->bounds;

		( $n, $d ) = $obj->approx( $input->{maxD} );;

		is $n, $input->{n}, "multiple; n";
		is $d, $input->{d}, "multiple; d";

		# check that injecting bounds works
		$obj = Math::Rational::Approx::MaxD->new( x => $input->{x},
		                                          maxD => $input->{maxD0},
		                                          bounds => $bounds
		                                        );

		( $n, $d ) = $obj->approx( $input->{maxD} );;

		is $n, $input->{n}, "bounds; n";
		is $d, $input->{d}, "bounds; d";

	};

}


done_testing;


