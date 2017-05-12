use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'JavaScript::Prepare',
    AUTHOR              => 'Mark Norman Francis <norm@cackhanded.net>',
    VERSION_FROM        => 'lib/JavaScript/Prepare.pm',
    ABSTRACT_FROM       => 'lib/JavaScript/Prepare.pm',
    PL_FILES            => {},
    EXE_FILES           => [
        'bin/jsprepare',
    ],
    PREREQ_PM           => {
        'Modern::Perl'              => 0,
        'version'                   => 0,
        # 'JavaScript::JSLint'        => 0,
        'JavaScript::Minifier::XS'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'JavaScript-Prepare-*' },
);
