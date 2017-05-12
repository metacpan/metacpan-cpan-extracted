use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Lingua::Stem::UniNE',
    license       => 'Perl_5',
    create_readme => 1,
    configure_requires => {
        'Module::Build'     => '0.3622',
        'Software::License' => 0,
    },
    build_requires => {
        'open'         => 0,
        'English'      => 0,
        'Pod::Man'     => '2.04',
        'String::Dump' => '0.05',
        'Test::More'   => '0.82',
    },
    requires => {
        # Perl v5.19.4—v5.19.11 has an incompatible bug:
        # https://rt.perl.org/Public/Bug/Display.html?id=121778
        'perl' => join(', ',
            '>= 5.8.1',
            map { "!= 5.19.$_" } 4 .. 11
        ),
        'charnames'          => 0,
        'namespace::clean'   => 0,
        'parent'             => 0,
        'strict'             => 0,
        'utf8'               => 0,
        'warnings'           => 0,
        'Carp'               => 0,
        'Exporter'           => 0,
        'Moo'                => '1.001000',
        'Unicode::CaseFold'  => 0,
        'Unicode::Normalize' => 0,
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/lingua-stem-unine-pm5.git',
            homepage   => 'https://github.com/patch/lingua-stem-unine-pm5',
            bugtracker => 'https://github.com/patch/lingua-stem-unine-pm5/issues',
        },
    },
);

$builder->create_build_script;
