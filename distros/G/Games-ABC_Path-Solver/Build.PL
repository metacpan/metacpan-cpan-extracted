use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Games::ABC_Path::Solver',
    license             => 'mit',
    dist_abstract       => 'A Solver for ABC Path',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    build_requires => {
        'Test::Differences' => 0,
        'Test::More' => 0,
    },
    requires => {
        'base' => 0,
        'Carp' => 0,
        'Getopt::Long' => '2.36',
        'Pod::Usage' => 0,
        'perl' => '5.008',
        'strict' => 0,
        'warnings' => 0,
    },
    add_to_cleanup      => [ 'Games-Solitaire-Verify-*' ],
    create_makefile_pl => 'traditional',
    script_files => [
        "scripts/abc-path-solve",
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
