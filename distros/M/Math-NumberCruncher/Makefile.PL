use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'        => 'Math::NumberCruncher',
    'VERSION_FROM'    => 'NumberCruncher.pm', # finds $VERSION
    'PREREQ_PM'        => { "Math::BigInt"   => 1.47 }, # e.g., Module::Name => 1.1
);
