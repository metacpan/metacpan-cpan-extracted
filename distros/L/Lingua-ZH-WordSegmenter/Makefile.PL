use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::ZH::WordSegmenter',
    AUTHOR              => 'Zhang Jun <jzhang533@gmail.com>',
    VERSION_FROM        => 'lib/Lingua/ZH/WordSegmenter.pm',
    ABSTRACT_FROM       => 'lib/Lingua/ZH/WordSegmenter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.64,
	'Encode'=>2.18
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-ZH-WordSegmenter-*' },
);
  
