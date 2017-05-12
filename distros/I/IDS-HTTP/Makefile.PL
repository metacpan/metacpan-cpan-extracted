use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IDS::Test',
    AUTHOR              => 'Kenneth Ingham <cpan@i-pi.com>',
    VERSION_FROM        => 'lib/IDS/DataSource/HTTP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IDS-*' },
);
