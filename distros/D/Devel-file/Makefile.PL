use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::file',
    AUTHOR              => 'Brad Bowman <perl-cpan@bereft.net>',
    VERSION_FROM        => 'lib/Devel/file.pm',
    ABSTRACT_FROM       => 'lib/Devel/file.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-file-*' },
);
