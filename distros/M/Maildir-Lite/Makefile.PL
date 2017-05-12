use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Maildir::Lite',
    AUTHOR              => 'Deian Stefan <stefan@cooper.edu>',
    VERSION_FROM        => 'lib/Maildir/Lite.pm',
    ABSTRACT_FROM       => 'lib/Maildir/Lite.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.01,
        'Sys::Hostname' => 1.11,
        'File::Sync' => 0.09,
        'Test::Files' => 0.14,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Maildir-Lite-*' },
);
