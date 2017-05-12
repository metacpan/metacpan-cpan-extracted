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
    module_name       => 'HTML::Template::Compiled::Plugin::I18N',
    license           => 'perl',
    dist_abstract     => 'HTML::Template::Compiled::Plugin::I18N - Internationalization for HTC',
    dist_author       => 'Steffen Winkler <steffenw at cpan.org>',
    dist_version_from => 'lib/HTML/Template/Compiled/Plugin/I18N.pm',
    requires          => {
        perl                       => 5.006,
        'HTML::Template::Compiled' => '0.93',
        $is_ppm
        ? ()
        : (
            Carp           => 0, # perl dist
            English        => 0, # perl dist
            'Hash::Util'   => 0, # perl dist
            'Data::Dumper' => 0, # perl dist
        ),
    },
    build_requires => {
        'Test::NoWarnings'  => 0,
        'Test::Exception'   => 0,
        'Test::Differences' => 0,
        parent              => 0,
        'Class::Singleton'  => 0,
        $is_ppm
        ? (
           'Test::Simple' => 0, # for Test::More
        )
        : (
            Cwd          => 0, # perl dist
            'Test::More' => 0,
        ),
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
