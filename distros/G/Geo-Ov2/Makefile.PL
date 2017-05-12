use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Geo::Ov2',
    AUTHOR              => 'Petr Vraník <hPa@SuTeren.net>',
    VERSION_FROM        => 'lib/Geo/Ov2.pm',
    EXE_FILES		=> ['ttn2device', 'getpoi.cron.sh', 'getpoi.sh'],
    ABSTRACT_FROM       => 'lib/Geo/Ov2.pm',
    PL_FILES            => {},
    PREREQ_FATAL        => 0,
    PREREQ_PRINT        => 1,
    NORECURS            => 0,
    #DIR                 => [ 'l10n' ],
    PREREQ_PM           => {
        'Test::More'             => 0,
	'IO::File'               => 0,
	'Carp'                   => 0,
	'POSIX'                  => 0,
	'locale'                 => 0,
	'File::Copy'             => 0,
	'File::Basename'         => 0,
	'Config::General'        => 0,
	'Pod::Usage'             => 0,
	'Getopt::Long'           => 0,
	'File::Copy'             => 0,
	'Locale::TextDomain'     => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Geo-Ov2-*' },
);
