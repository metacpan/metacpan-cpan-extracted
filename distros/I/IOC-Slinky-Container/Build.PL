use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IOC::Slinky::Container',
    license             => 'perl',
    dist_author         => 'Dexter Tad-y <dtady@cpan.org>',
    dist_version_from   => 'lib/IOC/Slinky/Container.pm',
    build_requires => {
        'Test::More'            => 0,
        'Test::Exception'       => 0,
        'Class::Load'           => 0,
        'Moose'                 => 0,
        'DateTime'              => 0,
        'DBD::SQLite'           => 0,
    },
    requires            => {
        'Carp'                  => 0,
        'YAML'                  => 0,
        'Scalar::Util'          => 0,
    },
    add_to_cleanup      => [ 'IOC-Slinky-Container-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
