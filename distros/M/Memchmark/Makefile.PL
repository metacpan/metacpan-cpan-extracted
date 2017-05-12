use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(NAME => 'Memchmark',
	      VERSION_FROM => 'lib/Memchmark.pm',
	      PREREQ_PM => { Proc::ProcessTable => 0,
			     Time::HiRes => 0,
			     Test::More => 0 },
	      ABSTRACT_FROM  => 'lib/Memchmark.pm',
	      AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>' );
