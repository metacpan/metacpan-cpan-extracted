use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Games::Sudoku::Solver',
    license             => 'perl',
    dist_author         => 'Dr.-Ing. Fritz Mehner <mehner@fh-swf.de>',
    dist_version_from   => 'lib/Games/Sudoku/Solver.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Games-Sudoku-Solver-*' ],
);

$builder->create_build_script();
