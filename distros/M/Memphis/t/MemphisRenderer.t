#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Memphis;
use FindBin;
use File::Spec;
use Cairo;

exit main() unless caller;


sub main {
	my $renderer = Memphis::Renderer->new();
	isa_ok($renderer, 'Memphis::Renderer');

	is($renderer->get_resolution, 256, "get_resolution");
	is($renderer->get_row_count(1), 2, "get_row_count");
	is($renderer->get_column_count(1), 2, "get_column_count");
	is($renderer->get_min_x_tile(1), -1, "get_min_x_tile");
	is($renderer->get_max_x_tile(1), -1, "get_max_x_tile");
	is($renderer->get_min_y_tile(1), -1, "get_min_y_tile");
	is($renderer->get_max_y_tile(1), -1, "get_max_y_tile");

	ok(!$renderer->tile_has_data(100, 100, 1), "tile_has_data");
	is($renderer->get_rule_set, undef, "get_rule_set");
	is($renderer->get_rule_set, undef, "get_rule_set");

	my $map = Memphis::Map->new();
	$map->load_from_file(File::Spec->catfile($FindBin::Bin, 'map.osm'));
	$renderer->set_map($map);
	is($renderer->get_map, $map, "set_map");

	my $rule_set = Memphis::RuleSet->new();
	$rule_set->load_from_file(File::Spec->catfile($FindBin::Bin, 'rule.xml'));
	$renderer->set_rule_set($rule_set);
	is($renderer->get_rule_set, $rule_set, "set_rule_set");

	$renderer->set_resolution(128);
	is($renderer->get_resolution, 128, "set_resolution");

	# Draw into a file
	my $file = "a.png";
	ok(! -e $file, "png file ($file) doesn't exist yet");
	$renderer->draw_png($file, 1);
	ok(-e $file, "draw_png");
	unlink($file);

	# Draw through Cairo
	my $surface = Cairo::ImageSurface->create('argb32', 100, 100);
	my $cr = Cairo::Context->create($surface);
	$renderer->draw_tile($cr, $surface->get_width, $surface->get_height, 1);

	return 0;
}
