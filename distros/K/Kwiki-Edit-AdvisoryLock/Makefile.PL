use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::Edit::AdvisoryLock',
    AUTHOR              => 'Eric Anderson <eric@cordata.com>',
    VERSION_FROM        => 'lib/Kwiki/Edit/AdvisoryLock.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/Edit/AdvisoryLock.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-Edit-AdvisoryLock-*' },
);
