use 5.010001;
use Module::Build;
use strict;
use warnings;

my $build = Module::Build->new(
	module_name => 'Math::Polynomial::Solve',

	dist_abstract => 'Find the roots of polynomial equations',
	dist_author => ['John M. Gamble <jgamble@cpan.org>'],
	dist_version => '2.86',
	dist_name => 'Math-Polynomial-Solve',

	provides => {
		'Math::Polynomial::Solve' => {
			file => 'lib/Math/Polynomial/Solve.pm',
		},
	},

	requires => {
		perl=> '5.10.1',
		'Math::Complex'=> '1.36',  # Bugfix of Im().
		'Math::Utils' => '1.12',
	},

	configure_requires => {
		'Module::Build' => '0.4',
	},

	build_requires => {
		'Test::More' => 0
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config => 0,
	release_status => 'stable',
	add_to_cleanup	 => [ 'Math-Polynomial-Solve-*' ],

	meta_merge => {
		keyword => [ qw(math polynomial quadratic cubic quartic matrix
				companion-matrix polynomial-zeros
			        Sturm Nickalls Ferrari Laguerre Hessenberg
				Newton-Raphson) ],
		resources => {
			repository => 'git://github.com/jgamble/Math-Polynomial-Solve.git',
#			repository => {
#				url => 'git://github.com/jgamble/Math-Polynomial-Solve',
#				web => 'https://github.com/jgamble/Math-Polynomial-Solve',
#				type => 'git',
#			},
		},
	},

);

$build->create_build_script;
