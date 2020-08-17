use 5.012;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'Docker::Construct',
    license             => 'perl_5',
    dist_author         => q{Cameron Tauxe <camerontauxe@gmail.com>},
    dist_version_from   => 'lib/Docker/Construct.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
        'Test::Cmd'  => '1.09'
    },
    requires => {
        'perl'  => '5.012',
        'Carp'  => '0',
        'JSON'  => '0',
        'Scalar::Util'  => '0',
        'File::Spec::Functions'  => '0',
        'File::Path'  => '0'
    },
    add_to_cleanup     => [ 'Docker-Construct-*' ],
    meta_merge  => {
        resources => {
            repository => 'https://github.com/camtauxe/docker-construct.git'
        }
    }
);

$builder->create_build_script();
