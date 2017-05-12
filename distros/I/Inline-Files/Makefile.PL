
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME	=> q[Inline::Files],
              VERSION_FROM => 'lib/Inline/Files.pm',
              ABSTRACT_FROM => 'lib/Inline/Files.pm',
	      PREREQ_PM => {
                            'Filter::Util::Call' => 0,
                            Test                 => 0,
                            Cwd                  => 0,
                           },

	     );
