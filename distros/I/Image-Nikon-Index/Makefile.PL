#use 5.018002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::Nikon::Index',
    VERSION_FROM      => 'lib/Image/Nikon/Index.pm', # finds $VERSION
    PREREQ_PM         => { 'Image::ExifTool' => '8.60', },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/Nikon/Index.pm', # retrieve abstract from module
       AUTHOR         => 'Snehasis Sinha <snehasis@cpan.org>') : ()),
	($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
	   ('LICENSE' => 'perl') : ()),
	dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean             => { FILES => 'Image-Nikon-Index-*' },
);
