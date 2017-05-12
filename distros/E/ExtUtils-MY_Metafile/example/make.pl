use strict;
use warnings;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile;

my_metafile {
  no_index => {
    directory => [ qw(sample t inc), ],
  },
  license  => 'perl',
};

WriteMakefile(
  NAME                => 'MyTest',
  AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
  VERSION_FROM        => 'MyTest.pm',
  ABSTRACT_FROM       => 'MyTest.pm',
  PL_FILES            => {},
  PREREQ_PM => {
      'Test::More' => 0,
  },
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => 'ExtUtils-MY_Metafile-*' },
);
