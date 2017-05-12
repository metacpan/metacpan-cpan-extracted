use Module::Build;
use strict;
use warnings;

my $build = Module::Build->new(
	module_name => 'Games::Maze',

	dist_abstract => 'Create Mazes',
	dist_author => 'John M. Gamble <jgamble@cpan.org>',
	dist_version => '1.08',
	dist_name => 'Games-Maze',

	#
	# Packages in the same file need to be versioned here.
	#
	provides => {
		'Games::Maze' => {
			file => 'lib/Games/Maze.pm',
		},
		'Games::Maze::Quad' => {
			file => 'lib/Games/Maze.pm',
		},
		'Games::Maze::Hex' => {
			file => 'lib/Games/Maze.pm',
		},
	},

	requires => {
		perl => '5.8.3',
		parent => 0,
	},

	configure_requires => {
		'Module::Build' => '0.3624',
	},

	build_requires => {
		'Test::Simple' => 0,
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config => 0,

	meta_merge => {
		keywords => [qw(games maze mazes)],

		resources => {
			repository => 'git://github.com/jgamble/Games-Maze.git',
#			repository => {
#				url => 'git://github.com/jgamble/Games-Maze.git',
#				web => 'https://github.com/jgamble/Games-Maze',
#				type => 'git',
#			},
		},
	},
);

$build->create_build_script;
