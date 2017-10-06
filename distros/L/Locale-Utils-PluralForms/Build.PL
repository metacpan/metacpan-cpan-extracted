use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name       => 'Locale::Utils::PluralForms',
    license           => 'perl',
    dist_abstract     => 'Locale::Utils::PluralForms - Utils to use plural forms',
    dist_author       => 'Steffen Winkler <steffenw at cpan.org>',
    dist_version_from => 'lib/Locale/Utils/PluralForms.pm',
    requires          => {
        perl                        => '5.006',
        English                     => 0, # dist Perl
        'HTML::Entities'            => 0,
        'LWP::UserAgent'            => 0,
        Moose                       => 0,
        'MooseX::StrictConstructor' => 0,
        'namespace::autoclean'      => 0,
        Safe                        => 0, # dist Perl
    },
    build_requires => {
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
        'Test::More'        => 0, # dist Test-Simple
        'Test::NoWarnings'  => 0,
    },
    recommends => {
        'Test::Pod'           => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
    auto_configure_requires => 0,
    create_makefile_pl   => 'traditional',
    recursive_test_files => 0,
    add_to_cleanup       => [ qw(
        META.yml *.bak *.gz Makefile.PL
    ) ],
)->create_build_script;
