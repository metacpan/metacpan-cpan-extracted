use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lexical::Failure',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Lexical/Failure.pm',
    ABSTRACT_FROM       => 'lib/Lexical/Failure.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.014,
    PREREQ_PM => {
        'Test::More'            => 0,
        'Test::Effects'         => 0,
        'Scope::Upper'          => 0,
#        'PadWalker'             => 0,
        'Keyword::Simple'       => 0.02,
        'Hash::Util::FieldHash' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lexical-Failure-*' },
);



