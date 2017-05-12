use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Games::Go::SGF2misc::SVG',
    VERSION_FROM      => 'lib/Games/Go/SGF2misc/SVG.pm', 
    PREREQ_PM         => {
        'Image::LibRSVG'    => 0.03,
        'XML::LibXML'       => 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Games/Go/SGF2misc/SVG.pm', # retrieve abstract from module
       AUTHOR         => 'Orien Vandenbergh <orien@icecode.com>') : ()),
);
