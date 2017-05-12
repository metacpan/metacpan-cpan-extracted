use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'	     => 'Games::Euchre',
              'VERSION_FROM' => 'lib/Games/Euchre.pm',
              'PREREQ_PM'    => {
                   Games::Cards => '1.45',
                   List::Util   => '1.11', # needed for Scalar::Util
                   Scalar::Util => '1.11', # needed for weaken()
                },
              'PREREQ_PM'    => {Games::Cards => '1.45'},
              'EXE_FILES'    => ['scripts/euchre.pl'],
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/Games/Euchre.pm',
                AUTHOR        => 'Chris Dolan <chrisdolan@sourceforge.net') : ()),
              );
