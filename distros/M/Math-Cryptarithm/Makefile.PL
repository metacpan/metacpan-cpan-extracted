use 5.034000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::Cryptarithm',
    VERSION_FROM      => 'lib/Math/Cryptarithm.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Math/Cryptarithm.pm', # retrieve abstract from module
    AUTHOR            => 'FUNG Cheok-Yin <fungcheokyin@gmail.com>',
    LICENSE           => 'perl',
);
