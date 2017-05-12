

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Device::CableModem::SURFboard',
    VERSION_FROM => 'lib/Device/CableModem/SURFboard.pm', # finds \$VERSION
    AUTHOR       => 'Scott Mazur (scott@littlefish.ca)',
    ABSTRACT     => 'Get info from a Motorola \'SURFboard\'',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
