###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
#use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME              => 'Image::MetaData::JPEG',
  VERSION_FROM      => 'lib/Image/MetaData/JPEG.pm',
  PREREQ_PM         => {}, # e.g., Module::Name => 1.1
  META_MERGE  => {
    'meta-spec'  => { version => 2 },
    resources  => {
      repository => {
        type=> 'git',
        url => 'https://github.com/rjbs/Image-MetaData-JPEG.git',
        web => 'https://github.com/rjbs/Image-MetaData-JPEG',
      },
    },
  },
 clean             => {FILES => "*~ */*~ */*/*~ */*/*/*~ */*/*/*/*~"},
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
     (ABSTRACT_FROM  => 'lib/Image/MetaData/JPEG.pod',
      AUTHOR         => 'Stefano Bettelli <bettelli@cpan.org>') : ()),
);
