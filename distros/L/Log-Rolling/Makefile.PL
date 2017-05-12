use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Log::Rolling',
    AUTHOR              => 'Mark Luljak <fairlite@fairlite.com>',
    VERSION_FROM        => 'lib/Log/Rolling.pm',
    ABSTRACT_FROM       => 'lib/Log/Rolling.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Rolling-*' },
);
