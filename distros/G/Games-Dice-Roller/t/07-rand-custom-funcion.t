#!perl
use 5.010;
use strict;
use warnings;
use Test::More;


use_ok( 'Games::Dice::Roller' ); 
diag( "Trying to use Math::Random::MT to test a custom rand (if module is available)" );

SKIP: {
    eval { require Math::Random::MT };
    skip "Math::Random::MT not installed", 2 if $@;
    my $gen = Math::Random::MT->new();
	my $mt_dicer =  Games::Dice::Roller->new(
		sub_rand => sub{ 
				my $sides = shift; 
				return $gen->rand( $sides );			
		},
	);
	my ($res, $descr) = $mt_dicer->roll('13d4kh7');
	ok( $res >= 7, "succesfully used rand from Math::Random::MT as random number generator");
	ok( $res <= 28, "succesfully used rand from Math::Random::MT as random number generator")
}

done_testing;