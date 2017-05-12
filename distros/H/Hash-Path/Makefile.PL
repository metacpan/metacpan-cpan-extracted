use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hash::Path',
    AUTHOR              => 'Igor Sutton Lopes <igor.sutton@gmail.com>',
    VERSION_FROM        => 'lib/Hash/Path.pm',
    ABSTRACT_FROM       => 'lib/Hash/Path.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hash-Path-*' },
);
