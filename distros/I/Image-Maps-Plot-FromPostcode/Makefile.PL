use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Image::Maps::Plot::FromPostcode',
    'VERSION_FROM'	=> 'FromPostcode.pm',
    'PREREQ_PM'		=> {
		Image::Magick => 0.01,
		File::Basename => 0.01,
		Data::Dumper => 0.01,
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'FromPostcode.pm',
       AUTHOR     => 'Lee Goddard <lgoddard@cpan.org>')
     : ()
    ),
);

