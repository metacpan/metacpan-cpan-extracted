use strict;

use Module::Build;

Module::Build->new(
	module_name => 'Filesys::Virtual::DPAP',
	license => 'perl',
	requires => {
		'perl' => 5,
		'Class::Accessor::Fast' => 0,
		'Filesys::Virtual' => 0,
		'Net::DPAP::Client' => 0
	},
	create_makefile_pl => 'traditional',
	create_readme => 1,
	sign => 1
)->create_build_script;
