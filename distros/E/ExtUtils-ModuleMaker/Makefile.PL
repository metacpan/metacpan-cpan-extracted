use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'ExtUtils::ModuleMaker',
    VERSION_FROM => 'lib/ExtUtils/ModuleMaker.pm', # finds $VERSION
    AUTHOR       => 'R. Geoffrey Avery (modules@PlatypiVentures.com)',
    ABSTRACT     => 'A simple replacement for h2xs -XA',
    EXE_FILES    => [ 'script/eumm' ],
);
