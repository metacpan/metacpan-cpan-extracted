use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::Go::SGF::Grove',
    VERSION_FROM        => 'Grove.pm',
    ABSTRACT_FROM       => 'Grove.pm',
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                             PREOP => 'pod2text lib/Games/Go/SGF/Grove.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
                           },
    clean               => { FILES => 'Games-Go-SGF-Grove-*' },
);
