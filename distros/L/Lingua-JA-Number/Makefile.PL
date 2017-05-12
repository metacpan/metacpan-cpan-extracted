use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Lingua::JA::Number',
    VERSION_FROM => 'lib/Lingua/JA/Number.pm', # finds $VERSION
    AUTHOR       => 'Mike Schilli <m@perlmeister.com',
    ABSTRACT     => 'Translate Numbers to Japanese'
);
