use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME              => 'Devel::GDB',
   VERSION_FROM      => 'lib/Devel/GDB.pm',
   PREREQ_PM         => {'Test::More'  =>  0,
                         threads::shared => 0,
                         Thread::Semaphore => 0,
                        },
   ABSTRACT_FROM  => 'lib/Devel/GDB.pm',
   AUTHOR         => 'Antal Novak <afn@cpan.org>, Josef Ezra <jezra@cpan.org>',
  );
