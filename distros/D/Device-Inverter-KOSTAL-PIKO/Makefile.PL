use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Device::Inverter::KOSTAL::PIKO',
    AUTHOR        => q{Martin Sluka <perl@sluka.de>},
    VERSION       => 0.13,
    EXE_FILES     => [ map "bin/piko_$_", qw/collect dump merge/ ],
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Mouse'                => 0,
        'Carp'                 => 0,
        'Config::INI::Reader'  => 0,
        'DateTime'             => 0,
        'File::HomeDir'        => 0,
        'File::Spec'           => 0,
        'Getopt::Long'         => 0,
        'HTTP::Request'        => 0,
        'LWP::UserAgent'       => 0,
        'MouseX::NativeTraits' => 0, # or alternatively Moose
        'namespace::clean'     => 0,
        'Net::Netrc'           => 0,
        'Params::Validate'     => 0,
        'Scalar::Util'         => 0,
        'Test::More'           => 0,
        'URI'                  => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Device-Inverter-KOSTAL-PIKO-*' },

    META_MERGE => {
        resources => {
            homepage   => 'https://github.com/fany/Device-Inverter-KOSTAL-PIKO',
            repository => 'https://github.com/fany/Device-Inverter-KOSTAL-PIKO.git',
        },
    },
);
