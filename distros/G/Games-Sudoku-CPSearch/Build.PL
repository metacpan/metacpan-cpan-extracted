use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Games::Sudoku::CPSearch',
    license             => 'perl',
    dist_author         => 'Martin-Louis Bright <mlbright@gmail.com>',
    dist_version_from   => 'lib/Games/Sudoku/CPSearch.pm',
    build_requires => {
        'Test::More' => 0,
		'List::MoreUtils' => 0,
    },
    add_to_cleanup      => [ 'Games-Sudoku-CPSearch-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
