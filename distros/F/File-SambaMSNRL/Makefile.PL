use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::SambaMSNRL',
    AUTHOR              => 'Raphael Gommeaux <raphael.gommeaux@gmail.com>',
    VERSION_FROM        => 'lib/File/SambaMSNRL.pm',
    ABSTRACT_FROM       => 'lib/File/SambaMSNRL.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-SambaMSNRL-*' },
);
