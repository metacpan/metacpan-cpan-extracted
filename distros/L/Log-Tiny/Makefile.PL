use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Log::Tiny',
    AUTHOR              => 'Jordan M. Adler <jmadler@cpan.org>',
    VERSION_FROM        => 'lib/Log/Tiny.pm',
    ABSTRACT_FROM       => 'lib/Log/Tiny.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Tiny-*' },
);
