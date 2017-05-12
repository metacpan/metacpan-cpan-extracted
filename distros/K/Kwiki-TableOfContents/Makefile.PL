use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::TableOfContents',
    AUTHOR              => 'Eric Anderson <eric@afaik.us>',
    VERSION_FROM        => 'lib/Kwiki/TableOfContents.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/TableOfContents.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Test::More' => 0,
	'Kwiki::Prototype' => 0,
	'Kwiki::Scriptaculous' => 0,
	'Kwiki::JSON' => 0,
	'JSON' => 0,
	'Kwiki::Search' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-TableOfContents-*' },
);
