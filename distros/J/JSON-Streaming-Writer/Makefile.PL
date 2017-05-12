
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'JSON::Streaming::Writer',
    'VERSION_FROM' => 'lib/JSON/Streaming/Writer.pm',
    'PREREQ_PM'		=> {
        'IO::File' => 0,
        'Carp' => 0,
        'B' => 0,
    },
    ($] >= 5.005 ?
     (
      ABSTRACT_FROM => 'lib/JSON/Streaming/Writer.pm',
      AUTHOR     => 'Martin Atkins <mart@degeneration.co.uk>'
     ) : ()
    ),
  );
