use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name       => 'Locale::File::PO::Header',
    license           => 'perl',
    dist_abstract     => 'Locale::File::PO:Header - Utils to build/extract the PO header',
    dist_author       => 'Steffen Winkler <steffenw at cpan.org>',
    dist_version_from => 'lib/Locale/File/PO/Header.pm',
    requires          => {
        perl                        => '5.006',
        Moose                       => 0,
        'MooseX::StrictConstructor' => 0,
        'namespace::autoclean'      => 0,
        syntax                      => 0,
        'Syntax::Feature::Method'   => 0,
        Clone                       => 0,
    },
    build_requires => {
        'Test::More'        => 0, # dist Test-Simple
        'Test::NoWarnings'  => '1.03',
        'Test::Exception'   => 0,
        'Test::Differences' => '0.60',
    },
    recommends => {
        # build
        'Test::Pod'            => '1.14',
        'Test::Pod::Coverage'  => '1.04',
        'Pod::Coverage::Moose' => 0,
    },
    create_makefile_pl   => 'traditional',
    recursive_test_files => 0,
    add_to_cleanup       => [ qw(
        META.yml *.bak *.gz Makefile.PL
    ) ],
)->create_build_script;
