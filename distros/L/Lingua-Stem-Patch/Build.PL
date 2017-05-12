use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Lingua::Stem::Patch',
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
        'open'         => 0,
        'English'      => 0,
        'String::Dump' => '0.05',
        'Test::More'   => '0.82',
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
        'Moo'              => '1.001000',
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/lingua-stem-patch-pm5.git',
            homepage   => 'https://github.com/patch/lingua-stem-patch-pm5',
            bugtracker => 'https://github.com/patch/lingua-stem-patch-pm5/issues',
        },
    },
);

$builder->create_build_script;
