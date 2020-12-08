#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTML::GoogleMaps::V3',
    VERSION_FROM     => 'lib/HTML/GoogleMaps/V3.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.005',
    PREREQ_PM => {
      'Geo::Coder::Google' => .16,
      'Template'           => 2.00,
    },
    TEST_REQUIRES => {
        'Test::More'       => 1.001014,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/HTML/GoogleMaps/V3',
            repository => {
                type => 'git',
                url  => 'https://github.com/Humanstate/html-googlemaps-v3.git',
                web  => 'https://github.com/Humanstate/html-googlemaps-v3',
            },
            bugtracker => {
                web => 'https://github.com/Humanstate/html-googlemaps-v3/issues',
            },
        },
    }):()),
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
