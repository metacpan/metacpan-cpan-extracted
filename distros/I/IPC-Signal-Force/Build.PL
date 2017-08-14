{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "IPC::Signal::Force",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Exporter" => 0,
		"IPC::Signal" => "1.00",
		"POSIX" => 0,
		"parent" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	meta_merge => {
		"meta-spec" => { version => "2" },
		resources => {
			bugtracker => {
				mailto => "bug-IPC-Signal-Force\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=IPC-Signal-Force",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
