#!/usr/bin/env perl

use Test::Most tests => 2;
use Renard::Incunabula::Devel::TestHelper;
use Renard::Incunabula::Common::Setup;

use Intertangle::Taffeta::Color::RGB24;

subtest "Build RGB24 using value" => sub {
	my @values = (
		{ value => 0xFF0000, svg => 'rgb(255,0,0)'    },
		{ value => 0xFFFF00, svg => 'rgb(255,255,0)'  },
		{ value => 0xFFFFFF, svg => 'rgb(255,255,255)'},
		{ value => 0x0000FF, svg => 'rgb(0,0,255)'},
	);
	plan tests => scalar @values;

	for my $test (@values) {
		is(
			Intertangle::Taffeta::Color::RGB24->new( value => $test->{value} )->svg_value,
			$test->{svg},
			"$test->{value} gives $test->{svg}",
		);
	}
};

subtest "Build RGB24 using components" => sub {
	my $rgb24 = Intertangle::Taffeta::Color::RGB24->new( r8 => 50, g8 => 25, b8 => 0 );
	is $rgb24->r8, 50;
	is $rgb24->g8, 25;
	is $rgb24->b8,  0;

	is $rgb24->value, ( 50 << 16 ) + ( 25 << 8 );
};

done_testing;
