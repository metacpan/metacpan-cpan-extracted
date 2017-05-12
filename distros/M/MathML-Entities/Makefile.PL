use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'MathML::Entities',
    VERSION_FROM => 'lib/MathML/Entities.pm', # finds $VERSION
    AUTHOR       => 'Jacques Distler (distler@golem.ph.utexas.edu)',
    ABSTRACT     => 'Convert XHTML+MathML named entities to numeric character refs or utf-8 characters.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
