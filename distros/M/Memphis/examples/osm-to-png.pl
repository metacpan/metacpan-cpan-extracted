#!/usr/bin/perl

use strict;
use warnings;

use Memphis;

#
# Execute with:
#   perl examples/osm-to-png.pl t/map.osm t/rule.xml osm.png
#

exit main() unless caller;

sub main {
	die "Usage: map rules png [zoom-level]\n" unless @ARGV > 3;
	my ($map_file, $rules_file, $png_file, $zoom_level) = @ARGV;
	$zoom_level = 1 unless defined $zoom_level;

	my $renderer = Memphis::Renderer->new();

	# Load the OSM map
	my $map = Memphis::Map->new();
	$map->load_from_file($map_file);
	$renderer->set_map($map);

	# Load the OSM rules
	my $rule_set = Memphis::RuleSet->new();
	$rule_set->load_from_file($rules_file);
	$renderer->set_rule_set($rule_set);

	# Render the OSM map as a png file
	$renderer->draw_png($png_file, $zoom_level);

	return 0;
}
