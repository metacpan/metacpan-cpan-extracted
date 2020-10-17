#!/usr/bin/env perl

use Test::Most tests => 2;
use Intertangle::Taffeta::Color::RGBFloat;

subtest "SVG value" => sub {
	my $rgb_float = Intertangle::Taffeta::Color::RGBFloat->new(
		r_float => 0.25,
		g_float => 0.50,
		b_float => 0.75,
	);

	my $opt_decimal = qr/(\.0*)?/;
	like $rgb_float->svg_value, qr/
		\Qrgb(\E
			\Q25\E $opt_decimal \Q%, \E
			\Q50\E $opt_decimal \Q%, \E
			\Q75\E $opt_decimal \Q%\E
		\Q)\E/x;
};

subtest "RGB float triple" => sub {
	my $rgb_float = Intertangle::Taffeta::Color::RGBFloat->new(
		r_float => 0.25,
		g_float => 0.50,
		b_float => 0.75,
	);

	is_deeply [ $rgb_float->rgb_float_triple ],
		[ 0.25, 0.50, 0.75 ];
};

done_testing;
