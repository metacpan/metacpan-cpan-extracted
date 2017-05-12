use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Geo::Region',
    license       => 'Perl_5',
    create_readme => 1,
    configure_requires => {
        'Module::Build'     => '0.4004',
        'Software::License' => 0,
    },
    build_requires => {
        'Pod::Man' => '2.04',
    },
    test_requires => {
        'open'       => 0,
        'English'    => 0,
        'Test::Most' => '0.22',
    },
    requires => {
        'perl'             => '5.8.1',
        'namespace::clean' => 0,
        'parent'           => 0,
        'strict'           => 0,
        'utf8'             => 0,
        'warnings'         => 0,
        'Carp'             => 0,
        'Exporter'         => 0,
        'List::Util'       => '1.35',
        'Moo'              => '1.001000',
        'Scalar::Util'     => '1.10',
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/geo-region-pm5.git',
            homepage   => 'https://github.com/patch/geo-region-pm5',
            bugtracker => 'https://github.com/patch/geo-region-pm5/issues',
        },
    },
);

$builder->create_build_script;
