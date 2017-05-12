use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Next::OO',
    AUTHOR              => 'Boris Zentner <bzm@2bz.de>',
    VERSION_FROM        => 'lib/File/Next/OO.pm',
    ABSTRACT_FROM       => 'lib/File/Next/OO.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'File::Next' => 0.38,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Next-OO-*' },
);
