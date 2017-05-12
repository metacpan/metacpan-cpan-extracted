use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hash::Transform',
    AUTHOR              => 'Dave Trischuk <trischuk@gmail.com>',
    VERSION_FROM        => 'lib/Hash/Transform.pm',
    ABSTRACT_FROM       => 'lib/Hash/Transform.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hash-Transform-*' },
);
