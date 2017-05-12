use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Fuse::Filesys::Virtual',
    AUTHOR              => 'Toshimitsu FUJIWARA <tttfjw@gmail.com>',
    VERSION_FROM        => 'lib/Fuse/Filesys/Virtual.pm',
    ABSTRACT_FROM       => 'lib/Fuse/Filesys/Virtual.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Fuse::Class' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Fuse-Filesys-Virtual-* t/testdir cover_db' },
);
