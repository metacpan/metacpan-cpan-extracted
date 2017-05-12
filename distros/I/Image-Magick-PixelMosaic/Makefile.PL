use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Image::Magick::PixelMosaic',
    VERSION_FROM      => 'lib/Image/Magick/PixelMosaic.pm',
    PREREQ_PM         => {
      Image::Magick => q/6.2.4/
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/Magick/PixelMosaic.pm', # retrieve abstract from module
       AUTHOR         => 'KATOU Akira <turugina@cpan.org>') : ()),
);
