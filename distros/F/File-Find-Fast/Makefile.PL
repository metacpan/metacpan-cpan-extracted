use strict;
use warnings;
 
use 5.010;
 
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'File::Find::Fast',
  VERSION_FROM => 'lib/File/Find/Fast.pm',
  EXE_FILES    => [
    'scripts/find-fast.pl',
  ],
  PREREQ_PM    => {
  },
  BUILD_REQUIRES => {
    'File::Basename'   => 0.1,
    'File::Temp'       => 0.1,
    'File::Spec'       => 0.1,
    'Data::Dumper'     => 0.1,
    'Carp'             => 0.1,
    'Exporter'         => 0.1,
    'Getopt::Long'     => 0.1,
  },
  TEST_REQUIRES => {
    'Test::More'     => 0.47,
    'Path::Iterator::Rule' => '1.015',
    'File::Find' => 0.1,
    'Benchmark'  => 0.1,
  },
  MIN_PERL_VERSION => '5.12.0',
  LICENSE          => "gpl_3",
  dist=>{
    COMPRESS => "gzip -9f",
    SUFFIX   => "gz",
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/lskatz/file-find-fast',
        web => 'https://github.com/lskatz/file-find-fast',
      },
    },
  },
);

