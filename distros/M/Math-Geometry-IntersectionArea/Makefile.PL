use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Math::Geometry::IntersectionArea',
               VERSION_FROM  => 'lib/Math/Geometry/IntersectionArea.pm',
               PREREQ_PM     => { 'Math::Vector::Real' => 0 },
               ABSTRACT_FROM => 'lib/Math/Geometry/IntersectionArea.pm',
               AUTHOR        => 'Salvador Fandiño <sfandino@yahoo.com>',
             );
