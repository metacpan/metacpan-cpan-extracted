
use ExtUtils::MakeMaker;

WriteMakefile( NAME         => 'Math::Int64::C_API::Sample',
               VERSION_FROM => 'lib/Math/Int64/C_API/Sample.pm',
               PREREQ_PM    => { 'Math::Int64' => '0.34' },
               AUTHOR       => 'Eto Demerzel <eto.demerzel@usrobots.com>',
               LIBS         => [''],
               DEFINE       => '',
               INC          => '-I.',
               OBJECT       => '$(O_FILES)',
             );
