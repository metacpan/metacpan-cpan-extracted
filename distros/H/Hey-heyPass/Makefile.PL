

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Hey::heyPass',
    VERSION_FROM => 'lib/Hey/heyPass.pm', # finds \$VERSION
    AUTHOR       => 'Dusty Wilson (cpan-hey-heypass@dusty.hey.nu)',
    ABSTRACT     => 'Client for heyPass Centralized Authentication System',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'LWP::UserAgent' => 2.0,
                     'Storable' => 2.15,
                    },
);
