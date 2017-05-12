use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'GBPVR::CDBI',
    AUTHOR              => 'David Westbrook <dwestbrook@gmail.com>',
    VERSION_FROM        => 'lib/GBPVR/CDBI.pm',
    ABSTRACT_FROM       => 'lib/GBPVR/CDBI.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.44,
        'Class::DBI' => 0,
        'DBD::ODBC'  => 0,
        'Win32::TieRegistry' => 0,
        'File::Spec' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GBPVR-CDBI-*' },
);
