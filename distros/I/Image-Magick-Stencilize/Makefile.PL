use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'Image::Magick::Stencilize',
   VERSION_FROM => 'lib/Image/Magick/Stencilize.pm',
   PREREQ_PM => {
      'Image::Magick' => 0,
   },
);


