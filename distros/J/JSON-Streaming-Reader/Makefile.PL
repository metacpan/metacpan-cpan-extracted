
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'JSON::Streaming::Reader',
    'VERSION_FROM' => 'lib/JSON/Streaming/Reader.pm',
    'PREREQ_PM'		=> {
        'IO::File' => 0,
        'IO::Scalar' => 0,
        'Carp' => 0,
        'B' => 0,
    },
    ($] >= 5.005 ?
     (
      ABSTRACT_FROM => 'lib/JSON/Streaming/Reader.pm',
      AUTHOR     => 'Martin Atkins <mart@degeneration.co.uk>'
     ) : ()
    ),
  );
