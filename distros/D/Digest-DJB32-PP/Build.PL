use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Digest::DJB32::PP',
    license             => 'artistic_2',
    dist_author         => q{Richard THIBERT <thibs@cpan.org>},
    dist_version_from   => 'lib/Digest/DJB32/PP.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'Digest-DJB32-PP-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
