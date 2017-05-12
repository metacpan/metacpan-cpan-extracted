use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Interchange6::Currency',
    AUTHOR        => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM  => 'lib/Interchange6/Currency.pm',
    ABSTRACT_FROM => 'lib/Interchange6/Currency.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.47
        ? ( 'LICENSE' => 'perl' )
        : () ),
    BUILD_REQUIRES => {
        'Scalar::Util'    => 0,
        'Test::More'      => '0.94',    # subtest
        'Test::Exception' => 0,
        'Test::Warnings'  => 0,
        'Test::RequiresInternet' => '0.05',
    },
    PREREQ_PM => {
        'Carp'                           => 0,
        'Class::Load'                    => 0,
        'CLDR::Number'                   => 0,
        'CLDR::Number::Format::Currency' => 0,
        'Math::BigFloat'                 => '1.60',
        'Moo'                            => '2.000',
        'namespace::clean'               => 0,
        'Safe::Isa'                      => 0,
        'Sub::Quote'                     => 1.004006,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'Interchange6-Currency-*' },
    META_MERGE => {
        resources => {
            repository =>
              'https://github.com/interchange/Interchange6-Currency.git',
            bugtracker =>
              'https://github.com/interchange/Interchange6-Currency/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
