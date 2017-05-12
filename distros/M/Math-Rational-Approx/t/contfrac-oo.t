#!perl

use Math::Rational::Approx::ContFrac;

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

		my ($n, $d ) = 
		  Math::Rational::Approx::ContFrac->new( x => $input->{x},
		                                         n => $input->{N} )->approx;
		is $n, $input->{n}, "n";
		is $d, $input->{d}, "d";

		# test if multiple calls works
		return unless $input->{N} > 1;

		my $x = Math::Rational::Approx::ContFrac->new( x => $input->{x},
		                                               n => $input->{N} - 1 );
		( $n, $d ) = $x->approx;
		( $n, $d ) = $x->approx( 1 );

		is $n, $input->{n}, "multiple; n";
		is $d, $input->{d}, "multiple; d";

	};

}


done_testing;


