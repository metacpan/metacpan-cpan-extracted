use 5.001001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name   => 'Math::Brent',

	dist_abstract => 'Single Dimensional Function Minimisation and Root Finding',
	dist_author   => [q{J. A. R. Williams},
			q{John M. Gamble <jgamble@cpan.org>}],
	dist_version => '1.00',
	dist_name => 'Math-Brent',

	requires => {
		perl => '5.10.1',
		'Math::Utils' => 1.06,
		'Math::VecStat' => 0
	},

	configure_requires => {
		'Module::Build' => 0,
	},

	build_requires => {
		'Test::More' => 0,
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config => 0,
	release_status => 'stable',
	add_to_cleanup => [ 'Math-Brent-*' ],
	meta_merge => {
		keyword => [ qw(math minimisation zero-finding
				Brent) ],
		resources => {
			repository => 'git://github.com/jgamble/Math-Brent.git',
		},
	},
);

$builder->create_build_script();
