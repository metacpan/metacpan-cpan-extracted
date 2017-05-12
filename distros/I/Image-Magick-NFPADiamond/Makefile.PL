use 5.00;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::Magick::NFPADiamond',
    VERSION_FROM      => 'lib/Image/Magick/NFPADiamond.pm', # finds $VERSION
    PREREQ_PM         => {Image::Magick}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/Magick/NFPADiamond.pm', # retrieve abstract from module
       AUTHOR         => 'Erich Strelow <estrelow@ceresita.cl>') : ()),
);
