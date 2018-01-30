use 5.022000;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME              => 'Geo::Coordinates::MGRS::XS',
  VERSION_FROM      => 'lib/Geo/Coordinates/MGRS/XS.pm',
  PREREQ_PM         => { 'Test::More' => 0 },
  ABSTRACT_FROM     => 'lib/Geo/Coordinates/MGRS/XS.pm',
  AUTHOR            => 'umeldt',
  LICENSE           => 'perl',
  LIBS              => ['-lm'],
  DEFINE            => '',
  INC               => '-I.',
  OBJECT            => '$(O_FILES)',
);
