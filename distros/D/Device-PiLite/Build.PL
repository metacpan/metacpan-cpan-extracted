use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Device::PiLite',
    license             => 'perl',
    dist_author         => q{Jonathan Stowe <jns@gellyfish.co.uk>},
    dist_version_from   => 'lib/Device/PiLite.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Device::SerialPort'	=>	'1.04',
	'Moose'			=>	'2.1005',
    },
    add_to_cleanup     => [ 'Device-PiLite-*' ],
    create_makefile_pl => 'traditional',
    meta_merge	=>	{
	resources	=>	{
               repository => 'https://github.com/jonathanstowe/Device-PiLite',
	},
    },
);

$builder->create_build_script();
