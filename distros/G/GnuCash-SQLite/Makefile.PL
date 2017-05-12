use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME            => 'GnuCash::SQLite',
    VERSION_FROM    => 'lib/GnuCash/SQLite.pm', # finds $VERSION
    ABSTRACT        => 'A module to access GnuCash SQLite files',
    AUTHOR          => 'Hoe Kit CHEW <hoekit at gmail.com>',
    LICENSE         => 'perl',
    PREREQ_PM       => {
        'DBD::SQLite'       => 0,
        'DBI'               => 0,
        'Carp'              => 0,
        'UUID::Tiny'        => 1.04,
        'DateTime'          => 1.12,
        'Path::Tiny'        => 0.055
    }, # e.g., Module::Name => 1.1
    TEST_REQUIRES   => {
        'Test::Number::Delta'   => 0,
    },
);
