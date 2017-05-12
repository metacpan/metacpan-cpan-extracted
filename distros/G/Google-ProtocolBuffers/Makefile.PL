use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Google::ProtocolBuffers',
    AUTHOR           => 'Igor Gariev <gariev@hotmail.com>, the CISRT Gadgets Foundation <csirtgadgets.org>',
    ABSTRACT_FROM    => 'lib/Google/ProtocolBuffers.pm',
    VERSION_FROM     => 'lib/Google/ProtocolBuffers.pm',
    LICENSE          => 'PERL',
    EXE_FILES        => ['bin/protoc-perl'],
    MIN_PERL_VERSION => 5.012,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0.52,
    },
    'META_MERGE'  => {
        "resources"   => {
            "repository"    => 'https://github.com/csirtgadgets/google-protocolbuffers-perl.git',
            "bugtracker"    => 'https://github.com/csirtgadgets/google-protocolbuffers-perl/issues',
            "homepage"      => 'https://github.com/csirtgadgets/google-protocolbuffers-perl',
        },
    },
    PREREQ_PM => {
        'Parse::RecDescent' => 1.94,
        'Test::More'        => 0.52,
        'Math::BigInt'      => 0,
        'Class::Accessor'   => 0,
        'constant'          => 0,
        'Config'            => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'test-*' },
);
