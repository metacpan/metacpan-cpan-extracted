#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;
use Memphis;
use FindBin;
use File::Spec;


exit main() unless caller;


sub main {
	my $rule_set = Memphis::RuleSet->new();
	isa_ok($rule_set, 'Memphis::RuleSet');
	
	is_deeply(
		[ $rule_set->get_bg_color ],
		[ 255, 255, 255, 255 ],
		"get_bg_color"
	);
	$rule_set->set_bg_color(127, 100, 50, 0);
	is_deeply(
		[ $rule_set->get_bg_color ],
		[ 127, 100, 50, 0 ],
		"set_bg_color"
	);

	is_deeply(
		[ $rule_set->get_rule_ids ],
		[ ],
		"get_rule_ids"
	);

	my $file = File::Spec->catfile($FindBin::Bin, 'rule.xml');
	$rule_set->load_from_file($file);
	pass("load_from_file");
	generic_test($rule_set);

	$rule_set = Memphis::RuleSet->new();
	$rule_set->load_from_data(slurp($file));
	pass("load_from_data");
	generic_test($rule_set);

	return 0;
}


sub generic_test {
	my ($rule_set) = @_;
	
	my @rule_ids = qw(
		natural:water
		landuse|natural:wood|forest
		landuse:landfill|quarry
		religion:christian
		landuse:vineyard
		landuse:field|farm|farmland|allotments|village_green|recreation_ground|meadow|grass
		leisure:park|playground|playing_fields|garden|pitch|golf_course|common|green
		leisure:stadium|sports_centre|water_park
		leisure:track
		leisure:swimming_pool
		waterway:riverbank
		waterway:river
		waterway:stream
		waterway:canal
		waterway:drain
		waterway:dock
		natural|landuse:water|pond|lake
		landuse:reservoir
		landuse:basin
		building:*
		railway:monorail
		railway:preserved
		railway:narrow_gauge
		railway:rail
		highway:footway|track
		highway:cycleway|bridleway
		highway:track
		highway:residential|unclassified|pedestrian
		highway:tertiary
		highway:secondary
		highway:primary
		highway:trunk
		highway:motorway
	);
	is_deeply([ $rule_set->get_rule_ids ], \@rule_ids, "get_rule_ids");
	
	my $rule = $rule_set->get_rule('highway:motorway');
	isa_ok($rule, 'Memphis::Rule');
	is_deeply(
		$rule->keys,
		[ 'highway' ],
		"rule->keys",
	);
	is_deeply(
		$rule->values,
		[ 'motorway' ],
		"rule->values",
	);


	$rule_set->remove_rule('highway:motorway');
	pop @rule_ids;
	is_deeply([ $rule_set->get_rule_ids ], \@rule_ids, "remove_rule");

	$rule_set->set_rule($rule);
	push @rule_ids, 'highway:motorway';
	is_deeply([ $rule_set->get_rule_ids ], \@rule_ids, "remove_rule");
}


sub slurp {
	my ($file) = @_;
	local $/;
	open my $handle, $file or die "Can't read file $file because $!";
	my $content = <$handle>;
	close $handle;
	return $content;
}
