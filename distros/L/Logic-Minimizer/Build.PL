use 5.010001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name => 'Logic::Minimizer',

	dist_author => q{John M. Gamble <jgamble@cpan.org>},
	dist_abstract => q(Parent class for Logic minimizers like Quine-McCluskey),
	dist_version => '1.00',
	release_status => 'stable',

	provides => {
		'Logic::Minimizer' => {
			file => 'lib/Logic::Minimizer.pm',
		},
	},

	requires => {
		perl => '5.16.1',
		Moose => '2.16',
		Carp => 0,
		'List::Compare::Functional' => '0.53',
		'namespace::autoclean' => '0.16',
	},
	configure_requires => {
		'Module::Build' => '0.4224',
	},
	build_requires => {
		'Test::More' => 0,
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config  => 0,
	add_to_cleanup   => [ 'Logic-Minimizer-*' ],

	meta_merge => {
		keywords => [qw(boolean boolean-algebra logic truth-tables)],

		resources => {
			repository => 'git://github.com/jgamble/Logic-Minimizer',
#			repository => {
#				url => 'git://github.com/jgamble/Logic-Minimizer',
#				web => 'https://github.com/jgamble/Logic-Minimizer',
#				type => 'git',
#			},
		},
	},
);

$builder->create_build_script();
