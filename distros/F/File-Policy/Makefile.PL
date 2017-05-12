use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'File::Policy',
              VERSION_FROM  => 'lib/File/Policy.pm',
              PREREQ_PM => {
                                'File::Spec::Functions' => 0,
                                'Test::Assertions' => 0,
                                'Log::Trace' => 0,
                                'File::Slurp' => 0,
                           },
              ABSTRACT_FROM => 'lib/File/Policy.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
