use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Getopt::Lazy',
    AUTHOR              => 'Ruey-Cheng Chen <rueycheng@gmail.com>',
    VERSION_FROM        => 'lib/Getopt/Lazy.pm',
    ABSTRACT_FROM       => 'lib/Getopt/Lazy.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
	'File::Basename' => 1,
	'Text::Wrap' => 1,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Getopt-Lazy-*' },
);
