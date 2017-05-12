
use ExtUtils::MakeMaker;

WriteMakefile( NAME         => 'Math::GMPn',
               VERSION_FROM => 'lib/Math/GMPn.pm',
               PREREQ_PM    => {},
               AUTHOR       => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS         => ['-lgmp'],
               DEFINE       => '', # e.g., '-DHAVE_SOMETHING'
               INC          => '-I.', # e.g., '-I. -I/usr/include/other'
               # Un-comment this if you add C files to link with later:
               # OBJECT     => '$(O_FILES)', # link all the C files too
             );
