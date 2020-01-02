use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HO::class',
    license             => 'perl',
    dist_author         => 'Sebastian Knapp <sknpp@cpan.org>',
    dist_version        => '0.080',
    requires => {
        'perl' => '5.6.0',
        'Class::ISA' => '0.20',
        'Package::Subroutine' => '0.022'
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
            repository => 'git://github.com/p5-ho-develop/class.git',
            homepage => 'https://github.com/p5-ho-develop/class/tree/master'
        }
    }
);

$builder->create_build_script();
