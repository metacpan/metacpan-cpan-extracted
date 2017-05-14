use Module::Build;
use strict;
use warnings;

my $build = Module::Build->new(
	module_name => 'Math::Utils',

	dist_abstract => 'Useful mathematical functions not in Perl',
	dist_author => ['John M. Gamble <jgamble@cpan.org>'],
	dist_version => '1.10',
	dist_name => 'Math-Utils',

	requires => {
		perl=> '5.10.1',
	},

	configure_requires => {
		'Module::Build' => '0.4',
	},

	build_requires => {
		'Test::Simple' => 0
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config =>0,

	meta_merge => {
		keywords => [ qw(math math-utils
				sign logarithm comparison polymonial) ],
		resources => {
			repository => 'git://github.com/jgamble/Math-Utils.git',
#			repository => {
#				url => 'git://github.com/jgamble/Math-Utils',
#				web => 'https://github.com/jgamble/Math-Utils',
#				type => 'git',
#			},
		},
	},

);

$build->create_build_script;
