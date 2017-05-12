#/usr/lib/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Log::CVLogger',
    VERSION_FROM    => 'lib/Log/CSVLogger.pm',
    PREREQ_PM         => {
        Text::CSV_XS => 0.64,
        POSIX => 1.13,
        Path::Class => 0.16
    } # e.g., Module::Name => 1.1

);
