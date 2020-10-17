#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';
use TestHelper;

use Renard::Incunabula::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Intertangle::Taffeta::Graphics::Image::PNG;
use Intertangle::Yarn::Graphene;

my $png_path = try {
	Renard::Incunabula::Devel::TestHelper->test_data_directory->child(qw(PNG libpng ccwn3p08.png));
} catch {
	plan skip_all => "$_";
};

plan tests => 3;

my ($x, $y) = (30, 30);
my $gfx_png = Intertangle::Taffeta::Graphics::Image::PNG->new(
	data => $png_path->slurp_raw,
	origin => Intertangle::Yarn::Graphene::Point->new( x => $x, y => $y ),
);

subtest "Attributes" => sub {
	is $gfx_png->origin->x, $x, 'correct x position';
	is $gfx_png->origin->y, $y, 'correct y position';
	is $gfx_png->size->width, 32, 'correct width';
	is $gfx_png->size->height, 32, 'correct height';
};

subtest "Render to Cairo" => sub {
	my $cairo_data = TestHelper->cairo(
		render => $gfx_png,
		width => 100, height => 100  );

	my $surface = $cairo_data->{surface};

	ok( TestHelper->cairo_surface_contains(
		source_surface => $surface,
		sub_surface    => $gfx_png->cairo_image_surface,
		origin         => $gfx_png->origin,
	), 'the data from the original PNG is in the correct position' );
};

subtest "Render to SVG" => sub {
	my $svg = TestHelper->svg(
		render => $gfx_png,
		width => 100, height => 100  );

	like $svg->xmlify, qr|data:image/png;base64,iVBORw0KGgo|, 'XML has Base64 encoded PNG';
};

done_testing;
