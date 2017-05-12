use strict;

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'Locale::Maketext::Extract::DBI',
	dist_author        => 'Brian Cassidy <bricas@cpan.org>',
	license            => 'perl',
	create_readme      => 1,
	create_makefile_pl => 'traditional',
	script_files       => [ qw( bin/xgettextdbi ) ],
	requires           => {
		'Locale::Maketext::Lexicon' => 0,
		'DBI'                       => 0
	},
	build_requires     => {
		'Test::More'  => 0,
	},
);
$build->create_build_script;