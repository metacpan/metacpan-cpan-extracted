use 5.006;

use strict;
use warnings;

use lib './inc';

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Games::ABC_Path::Generator',
    license             => 'mit',
    # dist_abstract => q{A generator for ABC Path puzzle games},
    dist_author         => q{Shlomi Fish <shlomif@cpan.org>},
    dist_version_from   => 'lib/Games/ABC_Path/Generator.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    build_requires => {
        'Test::Differences' => 0,
        'Test::More' => 0,
    },
    requires => {
        'Carp' => 0,
        'Class::XSAccessor' => 0,
        'Exporter' => 0,
        'Games::ABC_Path::Solver::Base' => '0.3.0',
        'Games::ABC_Path::Solver::Constants' => '0.3.0',
        'Games::ABC_Path::Solver::Coord' => '0.3.0',
        'Games::ABC_Path::Solver::Board' => '0.3.0',
        'Getopt::Long' => '2.36',
        'integer' => 0,
        'perl' => 5.006,
        'strict' => 0,
        'warnings' => 0,
    },
    add_to_cleanup      => [ 'Games-ABC_Path-Generator-*' ],
    create_makefile_pl => 'traditional',
    script_files => [
        "scripts/abc-path-gen",
    ],
    meta_merge =>
    {
        resources =>
        {
            repository => "http://bitbucket.org/shlomif/abc-path",
            homepage => "http://www.shlomifish.org/open-source/projects/japanese-puzzle-games/abc-path/",
        },
        keywords =>
        [
            "abc",
            "game",
            "games",
            "generate",
            "generator",
            "grid",
            "letters",
            "path",
            "puzzle",
            "puzzles",
            "riddle",
            "riddles",
            "table",
        ],
    },
);

$builder->create_build_script();
