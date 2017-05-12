use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hash::Storage::Driver::DBI',
    AUTHOR              => q{Viktor Turskyi <koorchik@cpan.org>},
    VERSION_FROM        => 'lib/Hash/Storage/Driver/DBI.pm',
    ABSTRACT_FROM       => 'lib/Hash/Storage/Driver/DBI.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'Test::Deep'       => 0,
        'DBD::SQLite'      => 0,
        'Hash::Storage'    => 0,
        'DBI'              => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hash-Storage-Driver-DBI-*' },
);
