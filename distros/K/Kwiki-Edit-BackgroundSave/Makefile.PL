use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::Edit::BackgroundSave',
    AUTHOR              => 'Eric Anderson <eric@cordata.com>',
    VERSION_FROM        => 'lib/Kwiki/Edit/BackgroundSave.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/Edit/BackgroundSave.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Test::More' => 0,
	'Kwiki::Prototype' => 0,
	'JSON' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-Edit-BackgroundSave-*' },
);
