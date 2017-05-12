use 5.10.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Hash::MD5',
    AUTHOR           => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM     => 'lib/Hash/MD5.pm',
    ABSTRACT_FROM    => 'lib/Hash/MD5.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10.0,
    ,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'Digest::MD5'  => 0,
        'Exporter'     => 0,
        'Scalar::Util' => 1.42,
    },
    TEST_REQUIRES => {
        'FindBin'                 => 0,
        'Pod::Coverage::TrustPod' => 0,
        'Test::More'              => 0,
        'Test::Pod'               => 1.22,
        'Test::CheckManifest'     => 0.9,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mziescha/Hash-MD5.git',
                web  => 'https://github.com/mziescha/Hash-MD5',
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Hash-MD5-*' },
);
