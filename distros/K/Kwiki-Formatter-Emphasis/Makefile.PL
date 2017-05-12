use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::Formatter::Emphasis',
    AUTHOR              => 'Eric Anderson <eric@cordata.com>',
    VERSION_FROM        => 'lib/Kwiki/Formatter/Emphasis.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/Formatter/Emphasis.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-Formatter-Emphasis-*' },
);
