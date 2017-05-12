use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'EOL',
    AUTHOR              => 'Todd Wylie <perldev@monkeybytes.org>',
    VERSION_FROM        => 'lib/EOL.pm',
    EXE_FILES           => [ 'bin/eol' ],
    ABSTRACT_FROM       => 'lib/EOL.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'EOL-*' },
);
