use ExtUtils::MakeMaker;
WriteMakefile(
              NAME            => 'Devel::DProfLB',
              VERSION_FROM    => 'DProfLB.pm',
              ABSTRACT_FROM   => 'DProfLB.pm',
              AUTHOR          => 'Jeff Weisberg <http://www.tcp4me.com/>',
              PREREQ_PM       => {POSIX => 0},

	      clean => {FILES => 'tmon.out'},

);
