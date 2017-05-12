use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Lingua::Stem::Snowball',
    license           => 'perl',
    dist_author       => 'Marvin Humphrey <marvin at rectangular dot com>',
    dist_version_from => 'lib/Lingua/Stem/Snowball.pm',
    requires          => {
        'Test::More' => 0,
        'perl'       => '5.6.2',
    },
    build_requires => {
        'ExtUtils::CBuilder' => 0,
        'ExtUtils::ParseXS'  => 0,
    },
    add_to_cleanup =>
        [ 'Lingua-Stem-Snowball-*', 'MANIFEST.bak', 'Makefile' ],
    create_makefile_pl => 'passthrough',
    c_source           => 'libstemmer_c',
    #extra_compiler_flags => [
    #    '-Wall',               '-Wextra',
    #    '-pedantic',           '-ansi',
    #    '-DPERL_GCC_PEDANTIC', '-std=c89',
    #    ],
);

$builder->create_build_script();
