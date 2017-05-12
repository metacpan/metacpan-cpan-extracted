use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'MMS::Parser',
   AUTHOR        => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   VERSION_FROM  => 'lib/MMS/Parser.pm',
   ABSTRACT_FROM => 'lib/MMS/Parser.pm',
   PREREQ_PM     => {
      'version'           => 0,
      'Test::More'        => 0,
      'Path::Class'       => 0,
      'File::Slurp'       => 0,
      'Parse::RecDescent' => 0,
   },
   dist     => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
   clean    => {FILES    => 'MMS-Parser-*'},
   PL_FILES => {
      'lib/MMS/Parser/WorkHorse.pm.PL' =>
        'blib/lib/MMS/Parser/WorkHorse.pm',
   },
);
