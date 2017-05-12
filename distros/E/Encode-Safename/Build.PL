use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Encode::Safename',
    license             => 'LGPL_3_0',
    create_license      => 1,
    dist_author         => q{Bert Vanderbauwhede <batlock666@gmail.com>},
    dist_version_from   => 'lib/Encode/Safename.pm',
    dist_abstract       => 'An encoding for safe filenames.',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Encode::Encoding'          => 0,
        'Getopt::Long::Descriptive' => 0,
        'Parse::Lex'                => 0,
    },
    add_to_cleanup      => [ 'Encode-Safename-*' ],
    create_makefile_pl => 'traditional',
    script_files => [ 'script/safename' ],
);

$builder->create_build_script();
