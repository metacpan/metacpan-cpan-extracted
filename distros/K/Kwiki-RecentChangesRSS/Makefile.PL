use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::RecentChangesRSS',
    AUTHOR              => 'James Peregrino <jperegrino@post.harvard.edu>',
    VERSION_FROM        => 'lib/Kwiki/RecentChangesRSS.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/RecentChangesRSS.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::RSS'   => 0,
        'Kwiki'      => 0.33,
        'Spiffy'     => 0.24,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-RecentChangesRSS-*' },
);
