use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'Image::Magick::Thumbnail::PDF',
	VERSION_FROM => 'lib/Image/Magick/Thumbnail/PDF.pm',
	PREREQ_PM => {
		'Smart::Comments' => 0,
		'File::Path' => 0,
		'File::Copy' => 0,	
		'Image::Magick' => 0,
		'Image::Magick::Thumbnail' => 0,
		'File::Which' => 0,
      'Getopt::Std' => 1,
      'Test::Simple' => 0,
      'Carp' => 0,
      'Cwd' => 0,

	},
   ABSTRACT_FROM => 'lib/Image/Magick/Thumbnail/PDF.pm',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',
   LICENSE => 'perl',
 
);
