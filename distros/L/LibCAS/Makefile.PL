use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME     => 'LibCAS',
    AUTHOR   => q{"Michael Morris" <"michael.m.morris@gmail.com">},
    VERSION  => '0.02a',
    ABSTRACT => 'A library for interacting with Jasig\'s CAS server',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    MIN_PERL_VERSION => 5.8.8,
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More' => 0.86,
        'Apache2::Const' => 2.00,
        'Apache2::Log'   => 2.00,
        'Apache2::RequestRec' => 2.00,
        'Apache2::URI' => 2.00,
        'APR::Table'   => 0,
        'Data::Dumper' => 0,
        'HTTP::Cookies'  => 1.39,
        'LWP::UserAgent' => 2.0,
        'URI' => 1.35,
        'XML::LibXML' => 1.58
    },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'LibCAS-*' },
);
