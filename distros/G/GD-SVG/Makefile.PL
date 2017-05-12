use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GD::SVG',
    VERSION_FROM      => 'SVG.pm', # finds $VERSION
    PREREQ_PM         => {GD  => 0,
			  SVG => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'SVG.pm', # retrieve abstract from module
       AUTHOR         => 'Todd Harris <harris@cshl.org>') : ()),
);
