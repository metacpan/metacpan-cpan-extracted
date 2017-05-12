use strict;

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'Email::Store::Language',
	dist_author        => 'Brian Cassidy <bricas@cpan.org>',
	license            => 'perl',
	create_readme      => 1,
	create_makefile_pl => 'traditional',
	requires           => {
		'Email::Store'     => 0,
		'Lingua::Identify' => 0
	},
	build_requires     => {
		'Test::More'       => 0,
		'DBD::SQLite2'     => 0
	},
);

$build->create_build_script;
