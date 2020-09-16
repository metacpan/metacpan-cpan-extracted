use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Iterator::Records',
    AUTHOR           => q{Michael Roberts <michael@cpan.org>},
    VERSION_FROM     => 'lib/Iterator/Records.pm',
    ABSTRACT_FROM    => 'lib/Iterator/Records.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Iterator::Simple' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
               type => 'git',
               url  => 'https://github.com/Vivtek/Iterator-Records.git',
               web  => 'https://github.com/Vivtek/Iterator-Records',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Iterator-Records-*' },
);
