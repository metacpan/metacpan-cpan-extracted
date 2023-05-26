use 5.008000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'Image::MetaData::GQview',
   AUTHOR        => 'Klaus Ethgen <Klaus@Ethgen.ch>',
   VERSION_FROM  => 'lib/Image/MetaData/GQview.pm',
   ABSTRACT_FROM => 'lib/Image/MetaData/GQview.pm',
   LICENSE       => 'gpl_2',
   PL_FILES      => {},
   PREREQ_PM     => {
      'Cwd'	   => 0,
      'Fatal'	   => 0,
      'Carp'	   => 0,
      'version'    => 0,
   },
   dist          => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
   clean         => {FILES => 'Image-MetaData-GQview-*'},
   depend        => {Makefiel => '$(VERSION_FROM)'},
);
