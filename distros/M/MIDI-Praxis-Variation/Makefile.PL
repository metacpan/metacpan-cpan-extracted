

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'MIDI::Praxis::Variation',
    VERSION_FROM => 'lib/MIDI/Praxis/Variation.pm', # finds \$VERSION
    AUTHOR       => 'Craig Bourne (cbourne@cpan.org)',
    ABSTRACT     => 'Module abstract (<= 44 characters) goes here',
    PREREQ_PM    => {
										 'MIDI::Simple'	=> '0.81',
                     'Test::Simple' => 0.44,
                    },
);
