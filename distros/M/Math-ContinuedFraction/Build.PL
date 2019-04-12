use 5.010001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name => 'Math::ContinuedFraction',

	dist_author => q{John M. Gamble <jgamble@cpan.org>},
	dist_abstract => 'Create and manipulate continued fractions',
	dist_version => '0.14',
	release_status => 'stable',

	provides => {
		'Math::ContinuedFraction' => {
			file => 'lib/Math/ContinuedFraction.pm',
		},
	},

	requires => {
		perl => '5.10.1',
		Carp => 0,
		'Math::BigInt' => 1.999816,
		'Math::BigRat' => 0.2611,
	},

	configure_requires => {
		'Module::Build' => 0.4224,
	},

	build_requires => {
		'Test::More' => 0,
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config => 0,
	add_to_cleanup => [ 'Math-ContinuedFraction-*' ],

	meta_merge => {
		keyword => [qw(math continued-fraction sequences)],

		resources => {
		    repository => 'git://github.com/jgamble/Math-ContinuedFraction.git',
#		    repository => {
#			url => 'git://github.com/jgamble/Math-ContinuedFraction.git',
#			web => 'https://github.com/jgamble/Math-ContinuedFraction',
#			type => 'git',
#			},
		},
	},
);

$builder->create_build_script();
