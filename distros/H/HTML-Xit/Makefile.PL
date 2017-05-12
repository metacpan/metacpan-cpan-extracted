use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTML::Xit',
    AUTHOR           => q{Ersun Warncke <ersun.warncke@outlook.com>},
    VERSION_FROM     => 'lib/HTML/Xit.pm',
    ABSTRACT_FROM    => 'lib/HTML/Xit.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Data::Dumper'          => 0,
        'HTML::Selector::XPath' => 0,
        'Scalar::Util'          => 0,
        'XML::LibXML'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTML-Xit-*' },
);
