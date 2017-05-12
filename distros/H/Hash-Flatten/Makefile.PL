use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Hash::Flatten',
              VERSION_FROM  => 'lib/Hash/Flatten.pm',
              EXE_FILES     => [],
              PREREQ_PM => {
                            Test::Assertions => 0,
                            Log::Trace => 0,
                           },
              ABSTRACT_FROM => 'lib/Hash/Flatten.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
