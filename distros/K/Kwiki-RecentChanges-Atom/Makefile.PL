use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::RecentChanges::Atom',
    AUTHOR              => 'Steve Peters <steve@fisharerojo.org>',
    VERSION_FROM        => 'lib/Kwiki/RecentChanges/Atom.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/RecentChanges/Atom.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Kwiki'      => 0,
	'XML::Atom::Feed'  => 0,
	'XML::Atom::Entry' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-RecentChanges-Atom-*' },
);
