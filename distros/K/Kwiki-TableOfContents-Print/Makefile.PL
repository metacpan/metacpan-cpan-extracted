use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::TableOfContents::Print',
    AUTHOR              => 'Eric Anderson <eric@cordata.com>',
    VERSION_FROM        => 'lib/Kwiki/TableOfContents/Print.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/TableOfContents/Print.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Test::More' => 0,
	'Kwiki::TableOfContents' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-TableOfContents-Print-*' },
);
