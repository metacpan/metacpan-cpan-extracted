use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'Mac::CocoaDialog',
   AUTHOR        => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   VERSION_FROM  => 'lib/Mac/CocoaDialog.pm',
   ABSTRACT_FROM => 'lib/Mac/CocoaDialog.pm',
   PL_FILES      => {},
   PREREQ_PM     => {
      'Test::More'      => 0,
      'Test::Exception' => 0,
      'version'         => 0,
   },
   dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
   clean => {FILES    => 'Mac-CocoaDialog-*'},
);
