#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Memphis;

exit main() unless caller;


sub main {
	my $attr = Memphis::RuleAttr->new();
	isa_ok($attr, 'Memphis::RuleAttr');

	$attr->z_min(12);
	is($attr->z_min, 12, "z_min");

	$attr->z_max(24);
	is($attr->z_max, 24, "z_max");

	$attr->color_red(127);
	is($attr->color_red, 127, "color_red");

	$attr->color_green(128);
	is($attr->color_green, 128, "color_green");

	$attr->color_blue(130);
	is($attr->color_blue, 130, "color_blue");

	$attr->color_alpha(131);
	is($attr->color_alpha, 131, "color_alpha");

	$attr->style("a-style");
	is($attr->style, "a-style", "style");

	$attr->size(23.45);
	is($attr->size, 23.45, "style");


	my $copy = $attr->copy();
	isa_ok($copy, 'Memphis::RuleAttr');

	$copy->color_alpha(54);
	is($attr->color_alpha, 131, "color_alpha");
	is($copy->color_alpha, 54, "color_alpha");

	$copy->style("b-style");
	is($attr->style, "a-style", "style");
	is($copy->style, "b-style", "style");

	$copy->size(123.45);
	is($attr->size, 23.45, "style");
	is($copy->size, 123.45, "style");

	return 0;
}
