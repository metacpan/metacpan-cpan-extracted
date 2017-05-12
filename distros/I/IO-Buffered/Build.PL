use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'IO::Buffered',
    license            => 'perl',
    dist_author        => 'Troels Liebe Bentsen <troels@infopro.dk>',
    dist_version_from  => 'lib/IO/Buffered.pm',
    create_readme      => 1,
    create_makefile_pl => 'passthrough',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'           => '>= 5.8.0',
    }, 
    add_to_cleanup => [ 
        'IO-Buffered-*',
        'Makefile',
        'blib',
    ],
);

$builder->create_build_script();
