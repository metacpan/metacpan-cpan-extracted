BEGIN {

	use strict;
	use Test::More qw 'no_plan';
	use_ok('Drupal::Module::Starter');
	use_ok('YAML');
}

ok(my $s = Drupal::Module::Starter->new('t/config.yaml'));
isa_ok($s, 'Drupal::Module::Starter');
ok(my $yaml = $s->sample_yaml);
ok(Load($yaml), "Yaml load and parse");

diag("todo:  add a --pages option to auto-add menu callbacks and menu items");





