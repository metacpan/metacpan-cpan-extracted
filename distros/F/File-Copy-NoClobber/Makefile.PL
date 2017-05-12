use strict;
use warnings;
use utf8;
use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME         => 'File::Copy::NoClobber',
    AUTHOR      => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    VERSION_FROM => 'lib/File/Copy/NoClobber.pm',
    ABSTRACT_FROM => 'lib/File/Copy/NoClobber.pm',
    PREREQ_PM => {
        "Test::Most" => 0,
        "Test::Warnings" => 0,
        "autodie" => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => '<DISTRO>-*' },
);
