use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::Scriptaculous',
    AUTHOR              => 'Eric Anderson <eric@afaik.us>',
    VERSION_FROM        => 'lib/Kwiki/Scriptaculous.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/Scriptaculous.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Test::More' => 0,
	'Kwiki::Prototype' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-Scriptaculous-*' },
);
