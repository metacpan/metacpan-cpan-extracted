use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Mac::AppleSingleDouble',
    VERSION_FROM => 'lib/Mac/AppleSingleDouble.pm', # finds $VERSION
    AUTHOR       => 'Jamie Flournoy (jamie@white-mountain.org)',
    ABSTRACT     => 'A module for reading files in the AppleSingle and AppleDouble formats'
);
