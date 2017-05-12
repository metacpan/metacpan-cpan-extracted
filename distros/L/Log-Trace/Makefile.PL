use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Log::Trace',
              VERSION_FROM  => 'lib/Log/Trace.pm',
              PREREQ_PM => {
                            Test::More => 0,
                           },
              ABSTRACT_FROM => 'lib/Log/Trace.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
