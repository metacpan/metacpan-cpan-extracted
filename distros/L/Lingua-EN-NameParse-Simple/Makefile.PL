use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::EN::NameParse::Simple',
    AUTHOR              => q{Hugh Esco <hesco@campaignfoundations.com>},
    VERSION_FROM        => 'lib/Lingua/EN/NameParse/Simple.pm',
    ABSTRACT_FROM       => 'lib/Lingua/EN/NameParse/Simple.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'gpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
    'Test::More' => 0,
           'DBI' => 0,
       'DB_File' => 0,
         'Fcntl' => 0,
        'locale' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-EN-NameParse-Simple-*' },
);
