use strict;
use warnings;

use Module::Build;

my $is_ppm
    = (
        # install using ppm
        ! $ENV{AUTHOR_DIST}
        && eval 'require ActivePerl::PPM::Package'
    )
    || (
        # build ppm and ppd
        $ENV{AUTHOR_DIST}
        && $ENV{AUTHOR_DIST} eq 'ppm'
    );

Module::Build->new(
    module_name       => 'Locale::Utils::PluralForms',
    license           => 'perl',
    dist_abstract     => 'Locale::Utils::PluralForms - Utils to use plural forms',
    dist_author       => 'Steffen Winkler <steffenw at cpan.org>',
    dist_version_from => 'lib/Locale/Utils/PluralForms.pm',
    requires          => {
        perl                        => '5.006',
        Moose                       => 0,
        'MooseX::StrictConstructor' => 0,
        'namespace::autoclean'      => 0,
        syntax                      => 0,
        'Syntax::Feature::Method'   => 0, 
        'HTML::Entities'            => 0,
        $is_ppm
        ? (
            'libwww-perl'  => 0,
            'HTML::Parser' => 0,
        )
        : (
            English          => 0, # dist Perl
            Safe             => 0, # dist Perl
            'LWP::UserAgent' => 0,
            'HTML::Entities' => 0,
        )
    },
    build_requires => {
        'Test::NoWarnings'  => 0,
        'Test::Exception'   => 0,
        'Test::Differences' => 0,
        $is_ppm
        ? (
            'Test::Simple' => 0,
        )
        : (
            'Test::More' => 0, # dist Test-Simple
        )
    },
    recommends => {
        # build
        'Test::Pod'           => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup       => [ qw(
        META.yml *.bak *.gz Makefile.PL
    ) ],
)->create_build_script();
