use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
	module_name => 'Math::Fortran',

	dist_abstract => q(Implementations of Fortran's sign() and log10().),
	dist_author => [q{J. A. R. Williams},
			q{John M. Gamble <jgamble@cpan.org>}],
	dist_version => '0.03',

	requires => {
		perl => '5.8.3',
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
	release_status      => 'stable',
	add_to_cleanup     => [ 'Math-Fortran-*' ],
);

$builder->create_build_script();
