# vi: ts=4 sw=4

use strict;
use warnings;

use Module::Build;

Module::Build->new(module_name => 'Fuse::DAAP',
	license => 'perl',
	requires => {'perl' => 5,
		'Fuse' => 0,
		'Net::DAAP::Client' => 0},
	create_makefile_pl => 'traditional',
	create_readme => 1,
	script_files => 'examples/fusedaap',
	sign => 1)->create_build_script;
