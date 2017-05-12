
require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Geo::Coordinates::UTM::XS',
               VERSION_FROM => 'lib/Geo/Coordinates/UTM/XS.pm',
               PREREQ_PM => { 'Geo::Coordinates::UTM' => 0.08,
                              'Test::More' => 0 },
               ABSTRACT_FROM => 'lib/Geo/Coordinates/UTM/XS.pm',
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS => [''],
               DEFINE => '',
               INC => '-I.' );

