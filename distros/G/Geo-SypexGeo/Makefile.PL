use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'Geo::SypexGeo',
  VERSION_FROM   => 'lib/Geo/SypexGeo.pm',
  PREREQ_PM      => {
                      'Text::Trim' => 0,
                      'Encode' => 0
  },
  ABSTRACT_FROM  => 'lib/Geo/SypexGeo.pm',
  AUTHOR         => 'Andrey Kuzmin <kak-tus@mail.ru>'
);
