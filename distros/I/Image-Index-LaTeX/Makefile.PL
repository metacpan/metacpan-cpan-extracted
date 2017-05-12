use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::Index::LaTeX',
    VERSION_FROM      => 'lib/Image/Index/LaTeX.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
    	'File::Find' 		=> 0,
    	'Image::Size' 	=> 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/Index/LaTeX.pm', # retrieve abstract from module
       AUTHOR         => 'Tom Kirchner <tk@local>') : ()),
);
