use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Getopt::FileConfig',
  VERSION_FROM => 'lib/Getopt/FileConfig.pm',
  AUTHOR       => 'Matevz Tadel (matevz.tadel@cern.ch)',
  ABSTRACT     => 'Module for taking options and their default values from a config-file.',
  LICENSE      => 'perl',

  PREREQ_PM    =>
  {
    "Getopt::Long" => 0,
  },
);
