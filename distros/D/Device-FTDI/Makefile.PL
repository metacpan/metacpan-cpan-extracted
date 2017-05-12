use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;

# Check if we have libftdi installed
my %lftdi_cfg;
eval {
    %lftdi_cfg = ExtUtils::PkgConfig->find(qw( libftdi libftdi1 ));
};
if ( my $err = $@ ) {
    warn $err;
    exit 0;
}

WriteMakefile(
    NAME          => 'Device::FTDI',
    AUTHOR        => 'Paul "LeoNerd" Evans <leonerd@leonerd.org.uk>',
    VERSION_FROM  => 'lib/Device/FTDI.pm',
    ABSTRACT      => 'use USB-attached serial interface chips from FTDI',
    INC           => $lftdi_cfg{cflags},
    LIBS          => [ $lftdi_cfg{libs} ],
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES           => {},
    PREREQ_PM          => {
        'Device::Chip::Adapter' => '0.02',
        'Future'                => 0,
        'Test::More'            => 0,
    },
    CONFIGURE_REQUIRES => { 'ExtUtils::PkgConfig' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0.94, },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'Device-FTDI-*' },
    depend     => { 'FTDI.c' => 'const_xs.inc' },
    META_MERGE => {
        resources => {
            homepage   => 'https://github.com/leonerd/perl-Device-FTDI',
            bugtracker => 'https://github.com/leonerd/perl-Device-FTDI/issues',
            repository => 'git://github.com/leonerd/perl-Device-FTDI',
            license    => 'http://dev.perl.org/licenses/',
        },
        x_contributors => [
            'Pavel Shaydo <zwon@cpan.org>',
            'Paul "LeoNerd" Evans <leonerd@leonerd.org.uk>',
        ],
    },
);

sub MY::postamble {
    return <<CONST;
const_xs.inc : util/generate_const.pl
\t$^X util/generate_const.pl

CONST
}
