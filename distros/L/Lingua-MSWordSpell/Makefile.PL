use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Lingua::MSWordSpell',
              VERSION_FROM  => 'lib/Lingua/MSWordSpell.pm',
              PREREQ_PM => {
                            Test::More => 0.42,
                            Win32::OLE => 0,
                           },
              ABSTRACT_FROM => 'lib/Lingua/MSWordSpell.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
