use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HO::class',
    license             => 'perl',
    dist_author         => 'Sebastian Knapp <rock@ccls-online.de>',
    dist_version        => '0.073',
    requires => {
        'perl' => '5.6.0',
        'Class::ISA' => '0.20',
        'Package::Subroutine' => 'v0.22'
    },
    configure_requires => { 
        'Module::Build' => 0.42 
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'Test::AbstractMethod' => 0
    },
    add_to_cleanup      => [ 'HO-class-*' ],
    create_makefile_pl  => 'traditional',
    meta_add => {
        resources => {
            repository => 'git://github.com/giftnuss/p5-ho-class.git',
            homepage => 'http://github.com/giftnuss/p5-ho-class/tree/master'
        }
    }
);

$builder->create_build_script();
