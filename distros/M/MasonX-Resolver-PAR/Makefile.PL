use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MasonX::Resolver::PAR',
    'VERSION_FROM'	=> 'lib/MasonX/Resolver/PAR.pm', # finds $VERSION
    'PREREQ_PM'		=> {HTML::Mason => 1.1, 
			    PAR => 0.62,
			    }, # 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/MasonX/Resolver/PAR.pm', # retrieve abstract from module
       AUTHOR     => 'Marcus Ramberg <draven@mo.himolde.no>') : ()),
);
