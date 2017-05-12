use 5.008006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Mail::Maps::Lookup',
    VERSION_FROM      => 'lib/Mail/Maps/Lookup.pm',
    PREREQ_PM         => {
	Net::DNS => 0.29,
	    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Mail/Maps/Lookup.pm',
       AUTHOR         => 'Matteo Cantoni <matteo.cantoni@nothink.org>') : ()),
);
