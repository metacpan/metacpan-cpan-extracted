use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'GD::OrgChart',
    'VERSION_FROM'	=> 'OrgChart.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	GD => 1.41
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'OrgChart.pm', # retrieve abstract from module
       AUTHOR     => 'Gary A. Algier <gaa@magpage.com>') : ()),
);
