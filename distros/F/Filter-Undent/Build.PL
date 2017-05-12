use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Filter::Undent',
    license             => 'perl',
    dist_author         => q{Anthony Kilna <anthony@kilna.com>},
    dist_version_from   => 'lib/Filter/Undent.pm',
    configure_requires  => { 'Module::Build' => 0.40 },
    build_requires      => { 'Test::More' => 0 },
    requires => {
        'perl'           => 5.006,
        'Filter::Simple' => 0,
    },
    add_to_cleanup      => [ 'Filter-Undent-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
