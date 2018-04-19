use 5.012;
use version;
use ExtUtils::MakeMaker;

my $version = '1.8.2';

WriteMakefile
(
    qw
    (
        NAME            Exporter::Proxy
        ABSTRACT_FROM   lib/Exporter/Proxy.pm
        LICENSE         perl
    ),

    VERSION     => version->parse( $version )->numify,
    AUTHOR      => 'Steven Lembark <lembark@wrkhors.com>',
    LICENSE     => 'perl',
    PREREQ_PM   =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.

        qw
        (
            strict      0
            Carp        0
            Symbol      0
            Test::More  0
            Test::Deep  0
        )
    }
);
