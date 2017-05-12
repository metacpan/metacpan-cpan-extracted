use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(NAME          => 'Math::Geometry::Voronoi',
              VERSION_FROM  => 'lib/Math/Geometry/Voronoi.pm',
              PREREQ_PM     => {Params::Validate => 0,
                                Scalar::Util     => 0,
                                List::Util       => 0,
                                Class::Accessor  => 0},
              ABSTRACT_FROM => 'lib/Math/Geometry/Voronoi.pm',
              AUTHOR        => 'Sam Tregar <sam@tregar.com>',
              LIBS          => [''],
              DEFINE        => '',
              INC           => '-I.',
              OBJECT =>
                'voronoi_main.o edgelist.o heap.o geometry.o memory.o '
                . 'output.o voronoi_core.o Voronoi.o');
