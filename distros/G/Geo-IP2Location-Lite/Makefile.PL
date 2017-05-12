#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Geo::IP2Location::Lite',
    VERSION_FROM     => 'lib/Geo/IP2Location/Lite.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.8.1',
    PREREQ_PM        => {
    },
    TEST_REQUIRES => {
        'Test::More'      => 0.31,
        'Test::Deep'      => 0.113,
        'Test::Exception' => 0.32
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Geo::IP2Location::Lite',
            bugtracker => 'https://github.com/Humanstate/geo-ip2location-lite/issues',
            repository => 'https://github.com/Humanstate/geo-ip2location-lite'
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
