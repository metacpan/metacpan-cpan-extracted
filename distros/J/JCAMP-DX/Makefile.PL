use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'JCAMP::DX',
    VERSION_FROM      => 'lib/JCAMP/DX.pm',
    LICENSE           => 'gpl_2',
    PREREQ_PM         => {
        Data::Dumper  => 0,
    },
    TEST_REQUIRES     => {
        Test::More    => 0,
        Test::Warn    => 0,
        Text::Diff    => 0,
    },
    AUTHOR            => 'Andrius Merkys <andrius.merkys@gmail.com>',
);
