use strict;

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'MARC::Crosswalk::DublinCore',
	dist_author        => 'Brian Cassidy <bricas@cpan.org>',
	license            => 'perl',
	create_readme      => 1,
	create_makefile_pl => 'traditional',
	script_files       => [ qw( bin/marc2dc ) ],
	requires           => {
		'DublinCore::Record' => 0,
		'MARC::Record'       => 0,
		'Test::More'         => 0
	},
);

$build->create_build_script;