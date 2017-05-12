use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Geo::Fips55',
    VERSION_FROM    => 'Fips55.pm', 
    PREREQ_PM       => { Geo::TigerLine => 0.02 }, 
    AUTHOR	    => 'Schuyler Erle <schuyler@nocat.net>',
);
