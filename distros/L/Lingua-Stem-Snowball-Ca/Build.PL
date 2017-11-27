use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Lingua::Stem::Snowball::Ca',
    license           => 'perl',
    dist_author       => 'Linas Valiukas <linas dot valiukas at gmail dot com>, Marvin Humphrey <marvin at rectangular dot com>, Israel Olalla of iSOCO <iolalla at isoco dot com>',
    dist_version_from => 'lib/Lingua/Stem/Snowball/Ca.pm',
    requires          => {
        'Test::More' => 0,
        'perl'       => '5.6.2',
    },
    build_requires => {
        'ExtUtils::CBuilder' => 0,
        'ExtUtils::ParseXS'  => 0,
    },
    add_to_cleanup =>
        [ 'Lingua-Stem-Snowball-Ca-*', 'MANIFEST.bak', 'Makefile' ],
    create_makefile_pl => 'passthrough',
    c_source           => 'libstemmer_c',
    #extra_compiler_flags => [
    #    '-Wall',               '-Wextra',
    #    '-pedantic',           '-ansi',
    #    '-DPERL_GCC_PEDANTIC', '-std=c89',
    #    ],
);

$builder->create_build_script();
