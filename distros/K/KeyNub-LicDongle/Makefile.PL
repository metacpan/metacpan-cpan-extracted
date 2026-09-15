# CPAN distribution. VERSION_FROM reads lib/KeyNub/LicDongle.pm, so the
# distribution carries the module's $VERSION. The distribution contains Perl
# source only; the native library is loaded at run time and is not bundled (its
# terms are in BINARY-LICENSE.txt).

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'KeyNub::LicDongle',
    AUTHOR           => 'KeyNub <support@keynub.com>',
    VERSION_FROM     => 'lib/KeyNub/LicDongle.pm',
    ABSTRACT         => 'Perl binding for the KeyNub USB-C license dongle',
    LICENSE          => 'apache_2_0',
    MIN_PERL_VERSION => '5.016',

    PREREQ_PM => {
        'FFI::Platypus' => '1.00',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://www.keynub.com/developers/perl/',
            repository => {
                type => 'git',
                url  => 'https://github.com/AB-KeyNub/KeyNub-SDK.git',
                web  => 'https://github.com/AB-KeyNub/KeyNub-SDK',
            },
            bugtracker => {
                web => 'https://github.com/AB-KeyNub/KeyNub-SDK/issues',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'KeyNub-LicDongle-*' },
);
