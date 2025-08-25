use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'MathML::Entities',
    VERSION_FROM => 'lib/MathML/Entities.pm', # finds $VERSION
    LICENSE      => 'perl',
    MIN_PERL_VERSION => '5.006',
    AUTHOR       => 'Jacques Distler (distler@golem.ph.utexas.edu)',
    ABSTRACT     => 'Convert XHTML+MathML named entities to numeric character refs or utf-8 characters.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Test::Pod' => 1.12,
                    },
);
