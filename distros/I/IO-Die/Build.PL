use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IO::Die',
    license             => 'artistic_2',
    dist_author         => q{Felipe Gasper <felipe@cpanel.net>},
    dist_version_from   => 'lib/IO/Die.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    test_requires => {
        perl            => '5.008',
        'Test::Class' => '0.41',
        'Test::Deep'  => '0.114',
        'Test::NoWarnings' => '0.01',
    },
    test_recommends => {
        'BSD::Resource' => '0',
    },
    requires => {
        perl => '5.006',    #should work, but the test suite will require 5.8
    },
    add_to_cleanup     => [ 'IO-Die-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
