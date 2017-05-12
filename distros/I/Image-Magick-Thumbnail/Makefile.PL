use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Image::Magick::Thumbnail',
    'VERSION_FROM'	=> 'lib/Image/Magick/Thumbnail.pm', # finds $VERSION
    'PREREQ_PM'		=> {Image::Magick=>0,}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Image/Magick/Thumbnail.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <cpan-at-leegoddard-dot-net>') : ()),
);
