

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Geo::SpaceManager',
    VERSION_FROM => 'lib/Geo/SpaceManager.pm', # finds \$VERSION
    AUTHOR       => 'Jim Gibson (Jim@Gibson.org)',
    ABSTRACT     => 'Place rectangles without overlap',
    PREREQ_PM    => {
                     'Test::Simple' => 0.62,
                     'Test::Number::Delta' => 0.16,
                    },
);
