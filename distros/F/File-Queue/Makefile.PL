use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Queue',
    AUTHOR              => 'Jason Lavold <jlavold@gmail.com>',
    VERSION_FROM        => 'lib/File/Queue.pm',
    ABSTRACT_FROM       => 'lib/File/Queue.pod',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Queue-*' },
);
