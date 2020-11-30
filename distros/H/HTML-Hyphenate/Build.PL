use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name => 'HTML::Hyphenate',
    license     => 'perl',
    dist_author => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    requires    => {
        'perl'                 => '5.16.0',
        'Moose'                => 0,
        'Mojolicious'          => 6.0,
        'Readonly'             => 1.03,
        'Set::Scalar'          => 0,
        'TeX::Hyphen'          => 0,
        'TeX::Hyphen::Pattern' => '1.1.5',
        'Pod::Usage'           => 0,
        'Getopt::Long'         => 0,
    },
    build_requires => {
        'Module::Build' => 0,
    },
    test_requires => {
        'File::Spec'         => 0,
        'Test::Compile'      => 0,
        'Test::TestCoverage' => 0,
        'Test::More'         => 0.86,
        'Test::Warn'         => 0,
    },
    script_files => [ qw(bin/hyphenate_html), ],
    sign         => 1,
    meta_merge   => {
        resources => {
            repository =>
              'https://bitbucket.org/rolandvanipenburg/html-hyphenate'
        }
    },
)->create_build_script;
