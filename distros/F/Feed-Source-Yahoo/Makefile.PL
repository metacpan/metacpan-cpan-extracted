use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Feed::Source::Yahoo',
    AUTHOR              => 'Emmanuel Di Pretoro <<manu@bjornoya.net>>',
    VERSION_FROM        => 'lib/Feed/Source/Yahoo.pm',
    ABSTRACT_FROM       => 'lib/Feed/Source/Yahoo.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'URI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Feed-Source-Yahoo-*' },
);
