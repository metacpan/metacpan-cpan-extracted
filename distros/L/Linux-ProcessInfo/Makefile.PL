use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'Linux::ProcessInfo',
    'VERSION_FROM' => 'lib/Linux/ProcessInfo.pm',
    'PREREQ_PM'		=> {
        'Sub::Name' => 0,
        'Carp' => 0,
    },
    ($] >= 5.005 ?
     (
      ABSTRACT_FROM => 'lib/Linux/ProcessInfo.pm',
      AUTHOR     => 'Martin Atkins <mart@degeneration.co.uk>'
     ) : ()
    ),
  );
