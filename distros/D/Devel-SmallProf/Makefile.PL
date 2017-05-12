use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile( NAME => 'Devel::SmallProf',
               VERSION_FROM => 'lib/Devel/SmallProf.pm',
	       ABSTRACT_FROM => 'lib/Devel/SmallProf.pm',
               PREREQ_PM => { 'Time::HiRes' => '1.20' },
               clean => { FILES => 'smallprof.out' } );

