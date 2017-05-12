use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/build_lib";
use Module::Build::FilterTests;

my $builder = Module::Build::FilterTests->new(
    module_name         => 'Gpx::Addons::Filter',
    license             => 'perl',
    dist_author         => 'Ingo LANTSCHNER <perl [at] lantschner.name>',
    dist_version_from   => 'lib/Gpx/Addons/Filter.pm',
    
    configure_requires => {
        'SUPER'                     => 0,
        'FindBin'                   => 0,
    },

    build_requires => {
        'Test::More'                => 0,
        'Test::Output'              => 0,
        'Sub::Identify'             => 0,
        
    },

    requires => {
        'perl'                      => '5.8.0',
        'Carp'                      => 0,
        'Data::Dumper'              => 0,
        'Geo::Gpx'                  => 0.13,
    },
    
    add_to_cleanup      => [ 'Gpx-Addons-Filter-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
