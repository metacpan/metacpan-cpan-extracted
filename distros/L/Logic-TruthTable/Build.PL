use 5.010001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name => 'Logic::TruthTable',

	dist_author => q{John M. Gamble <jgamble@cpan.org>},
	dist_abstract => q(Create a Boolean Truth Table),
	dist_version => '1.00',
	release_status => 'stable',

	provides => {
		'Logic::TruthTable' => {
			file => 'lib/Logic/TruthTable.pm',
		},
		'Logic::TruthTable::Convert81' => {
			file => 'lib/Logic/TruthTable/Convert81.pm',
		},
		'Logic::TruthTable::Util' => {
			file => 'lib/Logic/TruthTable/Util.pm',
		},
	},

	requires => {
		perl => '5.16.1',
		Moose => '2.16',
		Carp => 0,
		JSON => '2.61',
		'Convert::Base81' => '1.00',
		'Logic::Minimizer' => '1.00',
		'Module::Runtime' => '0.014',
		'Text::CSV' => 0,
		'namespace::autoclean' => '0.16',
	},
	configure_requires => {
		'Module::Build' => '0.4224',
	},
	build_requires => {
		'Test::More' => 0,
		'Test::Output' => 0,
		'Test::Deep' => '1.12',
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config  => 0,
	add_to_cleanup	 => [ 'Logic-TruthTable-*' ],

	meta_merge => {
		keywords => [qw(boolean boolean-algebra logic truth-table)],

		resources => {
			repository => 'git://github.com/jgamble/Logic-TruthTable',
#			repository => {
#				url => 'git://github.com/jgamble/Logic-TruthTable',
#				web => 'https://github.com/jgamble/Logic-TruthTable',
#				type => 'git',
#			},
		},
	},
);

$builder->create_build_script();
