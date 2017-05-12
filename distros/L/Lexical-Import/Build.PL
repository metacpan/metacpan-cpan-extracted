{ use 5.011002; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "Lexical::Import",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.011002",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"ExtUtils::CBuilder" => "0.15",
		"Module::Build" => 0,
		"Test::More" => 0,
		"constant" => 0,
		"perl" => "5.011002",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Carp" => 0,
		"Lexical::Var" => "0.006",
		"Module::Runtime" => "0.011",
		"Params::Classify" => 0,
		"XSLoader" => 0,
		"perl" => "5.011002",
		"strict" => 0,
		"warnings" => 0,
		"version" => "0.81",
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
