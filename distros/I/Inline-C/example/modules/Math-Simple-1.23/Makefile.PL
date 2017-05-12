use Inline::MakeMaker;

WriteMakefile( NAME => 'Math::Simple',
               VERSION_FROM => 'Simple.pm',
               PREREQ_PM => { Inline::C => 0.57 },
             );
