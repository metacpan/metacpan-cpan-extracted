#!/usr/bin/env perl

use Test::Most tests => 3;
use Renard::Incunabula::Common::Setup;

use Test::TypeTiny;

use Intertangle::Taffeta::Types qw(ColorLibrary RGB24Value Opacity);
use Color::Library;

subtest "ColorLibrary" => sub {
	should_pass(Color::Library->SVG->color('blue'), ColorLibrary, 'create Color::Library::Color directly');

	should_pass(ColorLibrary->coerce('svg:blue'), ColorLibrary, 'coercion from Str has correct type');

	is ColorLibrary->coerce('svg:blue')->value, 0x0000FF, 'svg:blue coercion';
	is ColorLibrary->coerce('svg:magenta')->value, 0xFF00FF, 'svg:magenta coerciion';

};

subtest "RGB24Value" => sub {
	should_pass( 0x0, RGB24Value );
	should_pass( 0x00FF00, RGB24Value );
	should_pass( 0xFFFFFF, RGB24Value );

	should_fail( -1, RGB24Value );
	should_fail( 0xFFFFFF + 1, RGB24Value );
};

subtest "Opacity" => sub {
	should_pass(0, Opacity);
	should_pass(1.0, Opacity);
	should_pass(0.5, Opacity);

	should_fail(-0.5, Opacity);
	should_fail(1.5, Opacity);
};

done_testing;
