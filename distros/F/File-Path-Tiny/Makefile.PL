use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'File::Path::Tiny',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/File/Path/Tiny.pm',
    ABSTRACT_FROM => 'lib/File/Path/Tiny.pod',
    PL_FILES      => {},
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'Test::More'      => 0,    # for unit tests
        'File::Temp'      => 0,    # for unit tests
        'Test::Exception' => 0,    # for unit tests
        'Cwd'             => 0,
        'Carp'            => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'File-Path-Tiny-*' },
);
