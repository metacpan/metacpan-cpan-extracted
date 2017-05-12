use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'IS::Conf',
    VERSION_FROM => 'lib/IS/Conf.pm', # finds $VERSION
    AUTHOR       => 'Steve Traugott (stevegt@TerraLuna.Org)',
    ABSTRACT     => 'Infrastructure Configuration Management'
);
