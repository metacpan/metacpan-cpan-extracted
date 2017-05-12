use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Fuse::Class',
    AUTHOR              => 'Toshimitsu FUJIWARA <tttfjw@gmail.com>',
    VERSION_FROM        => 'lib/Fuse/Class.pm',
    ABSTRACT_FROM       => 'lib/Fuse/Class.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Fuse' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Fuse-Class-* cover_db' },
);
