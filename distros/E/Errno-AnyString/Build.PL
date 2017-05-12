use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Errno::AnyString',
    license             => 'perl',
    dist_author         => 'Dave Taylor <dave.taylor.cpan@gmail.com>',
    dist_version_from   => 'lib/Errno/AnyString.pm',
    requires => {
        'perl'         => 5.006,
        'Scalar::Util' => 0,
        'Exporter'     => 0,
        'Carp'         => 0,
    },
    build_requires => {
        'Config'             => 0,
        'English'            => 0,
        'Errno'              => 0,
        'ExtUtils::CBuilder' => 0,
        'File::Slurp'        => 0,
        'Module::Build'      => 0,
        'Scalar::Util'       => 0,
        'Test::Exception'    => 0,
        'Test::More'         => 0,
        'Test::NoWarnings'   => 0,
        'Test::Taint'        => 0,
    },
    add_to_cleanup      => [ 'Errno::AnyString-*' ],
    create_makefile_pl => 'small',
);

$builder->create_build_script();
