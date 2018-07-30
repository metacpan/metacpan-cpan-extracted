use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name => 'HTML::Hyphenate',
    license     => 'perl',
    dist_author => 'Roland van Ipenburg <ipenburg@xs4all.nl>',
    requires    => {
        'perl'                 => '5.14.0',
        'Mojo::DOM'            => 0,
        'Log::Log4perl'        => 0,
        'Readonly'             => 1.03,
        'Set::Scalar'          => 0,
        'TeX::Hyphen'          => 0,
        'TeX::Hyphen::Pattern' => 0,
        'Moose'                => 0,
        'namespace::autoclean' => 0,
    },
    build_requires => {
        'Test::More'       => 0.86,
        'Test::NoWarnings' => 0,
    },
    test_requires => {
        'Test::Pod'            => 1.00,
        'Test::Pod::Coverage'  => 1.00,
        'Test::TestCoverage'   => 0.08,
        'Test::CheckManifest'  => 1.01,
        'Test::Kwalitee'       => 0,
        'Test::Warn'           => 0,
        'TeX::Hyphen::Pattern' => 0.103,
    },
    script_files => [ qw(bin/hyphenate_html), ],
    sign         => 1,
    meta_merge   => {
        resources => {
            repository => 'https://github.com/ipenburg/HTML-Hyphenate'
        }
    },
)->create_build_script;
