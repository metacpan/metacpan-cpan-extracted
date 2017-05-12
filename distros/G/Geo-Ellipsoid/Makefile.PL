

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Geo::Ellipsoid',
    VERSION_FROM => 'lib/Geo/Ellipsoid.pm',
    AUTHOR       => 'Peter John Acklam <pjacklam@online.no>',
    ABSTRACT     => 'Accurate latitude/longitude calculations',
    PREREQ_PM    => {
                     'Test::More' => 0.47,
                     'Test::Number::Delta' => 0.16, 
		     'Math::Trig' => 1.03,
		     'Scalar::Util' => 1.19,
		     'Carp' => 1.04,
                    },
);
