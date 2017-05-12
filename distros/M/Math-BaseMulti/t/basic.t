#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;

use Math::BaseMulti;

my $mbm = Math::BaseMulti->new(
	digits => [
		[ 'A'..'Z' ],
		[ 0..9, 'A'..'Z' ],
		[ 0..9, 'A'..'Z' ],
		[ 0..9 ],
	],
);

isa_ok( $mbm, 'Math::BaseMulti');

is ( $mbm->to(10), '10', 'basic ->to( 10 ) conversion');
is ( $mbm->to(1000), '2S0', 'basic ->to( 1000 ) conversion');
is ( $mbm->from('AAB0'), 3710, 'basic ->from( \'AAB0\' ) conversion');

$mbm->leading_zero(1);

is ( $mbm->to(10), 'A010', 'basic ->to( 10 ) conversion');
is ( $mbm->to(1000), 'A2S0', 'basic ->to( 1000 ) conversion');


