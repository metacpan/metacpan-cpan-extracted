use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::Magick::Iterator',
    VERSION_FROM      => 'lib/Image/Magick/Iterator.pm', # finds $VERSION
    PREREQ_PM         => {
                          Image::Magick => 5.56,
                          Image::PBMlib => 1.05,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/Magick/Iterator.pm', # retrieve abstract from module
       AUTHOR         => 'Allen Day <allenday@ucla.edu>') : ()),
);
