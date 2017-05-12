use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Lingua::Stem::Any',
    license       => 'Perl_5',
    create_readme => 1,
    configure_requires => {
        'Module::Build'     => '0.3622',
        'Software::License' => 0,
    },
    build_requires => {
        'open'       => 0,
        'English'    => 0,
        'Pod::Man'   => '2.04',
        'Test::More' => '0.82',
    },
    requires => {
        'perl'                   => '5.8.1',
        'namespace::clean'       => 0,
        'strict'                 => 0,
        'utf8'                   => 0,
        'warnings'               => 0,
        'Carp'                   => 0,
        'Lingua::Stem'           => '0.80',
        'Lingua::Stem::Patch'    => '0.04',
        'Lingua::Stem::Snowball' => '0.95',
        'Lingua::Stem::UniNE'    => '0.08',
        'List::Util'             => '1.33',
        'Moo'                    => '1.001000',
        'Unicode::CaseFold'      => 0,
        'Unicode::Normalize'     => 0,
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/lingua-stem-any-pm5.git',
            homepage   => 'https://github.com/patch/lingua-stem-any-pm5',
            bugtracker => 'https://github.com/patch/lingua-stem-any-pm5/issues',
        },
    },
);

$builder->create_build_script;
