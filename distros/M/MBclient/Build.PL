use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MBclient',
    license             => 'MIT',
    dist_author         => q{Loic Lefebvre <lle@cpan.org>},
    dist_version_from   => 'lib/MBclient.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.006_001',
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/sourceperl/MBclient'
        }
    },
    add_to_cleanup     => [ 'MBclient-*' ],
    #create_makefile_pl => 'traditional',
);

$builder->create_build_script();
