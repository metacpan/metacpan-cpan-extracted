use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Image::IPTCInfo::RasterCaption',
    'VERSION_FROM'	=> 'RasterCaption.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		"Image::Magick"		=> 0.1,
		"Image::IPTCInfo"	=> 1.6,
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'RasterCaption.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <lgoddard@cpan.org>') : ()),
);
