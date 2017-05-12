use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::SGF::Tournament',
    AUTHOR              => 'Al Nikolov <alnikolov@narod.ru>',
    VERSION_FROM        => 'lib/Games/SGF/Tournament.pm',
    ABSTRACT            => 'lib/Games/SGF/Tournament.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-SGF-Tournament-*' },
);
