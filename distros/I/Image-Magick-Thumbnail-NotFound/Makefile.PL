use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::Magick::Thumbnail::NotFound',
    VERSION_FROM      => 'lib/Image/Magick/Thumbnail/NotFound.pm', # finds $VERSION
	 ABSTRACT_FROM		 => 'lib/Image/Magick/Thumbnail/NotFound.pm',
    PREREQ_PM         => {
		'Image::Magick' => 0,
		'Image::Magick::Thumbnail' => 0,
		'Image::Magick::Square' => 0,
	 }, 
    ($] >= 5.005 ? (    ## Add these new keywords supported since 5.005
      AUTHOR         => 'Leo Charre <leo@leocharre.com>',
	   ABSTRACT_FROM	=> 'lib/Image/Magick/Thumbnail/NotFound.pm',		
		) : ()),
);
