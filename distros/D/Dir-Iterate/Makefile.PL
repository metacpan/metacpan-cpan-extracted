

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Dir::Iterate',
    VERSION_FROM => 'lib/Dir/Iterate.pm', # finds \$VERSION
    AUTHOR       => 'Brent Royal-Gordon (brentdax@cpan.org)',
    ABSTRACT     => 'map and grep for directory trees',
    PREREQ_PM    => {
                     'Test::More' => 0.80,
                    },
);
