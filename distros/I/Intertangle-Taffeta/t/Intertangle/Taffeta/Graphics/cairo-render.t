#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;
use Intertangle::Taffeta::Transform::Affine2D::Translation;
use Intertangle::Taffeta::Color::Named;
use Intertangle::Taffeta::Style::Fill;
use Intertangle::Taffeta::Graphics::Rectangle;

use lib 't/lib';
use TestHelper;

subtest "Draw on to Cairo surface" => fun() {
	require Cairo;
	my ($width, $height) = (500, 500);
	my $surface = Cairo::ImageSurface->create('argb32', $width, $height);

	my $cr = Cairo::Context->create( $surface );
	my @tx = (
		Intertangle::Taffeta::Transform::Affine2D::Translation->new( translate => [ 20,  20] ),
		Intertangle::Taffeta::Transform::Affine2D::Translation->new( translate => [100, 200] ),
	);

	my $graphics_f = {
		class => 'Intertangle::Taffeta::Graphics::Rectangle',
		params => {
			origin => [0, 0],
			width => 10, height => 20,
			fill => Intertangle::Taffeta::Style::Fill->new(
				color => Intertangle::Taffeta::Color::Named->new( name => 'svg:black' ),
			),
		},
	};

	my $subsurface = Cairo::ImageSurface->create('argb32',
		$graphics_f->{params}{width},
		$graphics_f->{params}{height});
	$graphics_f->{class}->new(
		%{ $graphics_f->{params} },
	)->render_cairo(
		Cairo::Context->create( $subsurface )
	);

	my @t_rect = map {
		my $gfx_rect = $graphics_f->{class}->new(
			%{ $graphics_f->{params} },
			transform => $_,
		);
	} @tx;

	$_->render_cairo( $cr ) for @t_rect;

	ok(
		TestHelper->cairo_surface_contains(
			source_surface => $surface,
			sub_surface => $subsurface,
			origin => $tx[$_]->translate ),
		"has rectangle at \$tx[$_]"
	) for 0..@tx-1;
};

done_testing;
