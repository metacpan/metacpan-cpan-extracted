use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Find::Node',
    AUTHOR              => 'Stephen C. Losen <scl@virginia.edu>',
    VERSION_FROM        => 'lib/File/Find/Node.pm',
    ABSTRACT_FROM       => 'lib/File/Find/Node.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Find-Node-*' },
);
