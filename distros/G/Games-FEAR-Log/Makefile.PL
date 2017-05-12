use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::FEAR::Log',
    AUTHOR              => 'Evan Kaufman <evank@cpan.org>',
    VERSION_FROM        => 'lib/Games/FEAR/Log.pm',
    ABSTRACT_FROM       => 'lib/Games/FEAR/Log.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBI'        => 1.50,
        'File::Copy' => 0,
        'File::Temp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-FEAR-Log-*' },
);
