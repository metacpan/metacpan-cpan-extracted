use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Geo::GNIS',
    VERSION_FROM    => 'GNIS.pm', 
    PREREQ_PM       => { Geo::TigerLine => 0.02 }, 
    AUTHOR	    => 'Schuyler Erle <schuyler@nocat.net>',
);
