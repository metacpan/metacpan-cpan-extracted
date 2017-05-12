use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Games::Sudoku::Preset',
    license             => 'perl',
    dist_author         => q{Klaus Wittrock <Wittrock#cpan.org>},
    dist_version_from   => 'lib/Games/Sudoku/Preset.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Tk' => 0,
    },
    add_to_cleanup     => [ 'Sudoku-Preset-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
