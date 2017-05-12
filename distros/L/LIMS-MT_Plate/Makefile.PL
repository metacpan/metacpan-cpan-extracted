use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'LIMS::MT_Plate',
    VERSION_FROM      => 'lib/LIMS/MT_Plate.pm', # finds $VERSION
    PREREQ_PM         => {
							Microarray => 0.43,
							Test::More => 0.64,
							Test::Group => 0.07,
							Test::Differences => 0.47,
							Test::Deep => 0.096,
							Test::Exception => 0.21							
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Christopher Jones <c.jones@ucl.ac.uk>') : ()),
);
