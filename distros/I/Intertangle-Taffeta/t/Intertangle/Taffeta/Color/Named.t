#!/usr/bin/env perl

use Test::Most tests => 1;
use Renard::Incunabula::Devel::TestHelper;
use Renard::Incunabula::Common::Setup;

use Intertangle::Taffeta::Color::Named;

subtest "Build named color" => sub {
	is(
		Intertangle::Taffeta::Color::Named->new( name => 'svg:blue' )->svg_value,
		'blue',
		'svg:blue gives blue');

	is(Intertangle::Taffeta::Color::Named->new( name => 'html:blue' )->svg_value,
		'rgb(0,0,255)',
		'html:blue gives rgb(0,0,255)');
};

done_testing;
