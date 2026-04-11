use strict;
use warnings;
use ExtUtils::MakeMaker;
use EV::MakeMaker;
use Alien::cares;

my %ev = EV::MakeMaker::ev_args();

WriteMakefile(
    NAME          => 'EV::cares',
    VERSION_FROM  => 'lib/EV/cares.pm',
    ABSTRACT      => 'High-performance async DNS resolver using c-ares and EV',
    AUTHOR        => 'vividsnow',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.012',
    PREREQ_PM     => {
        'EV'           => '4.11',
        'Alien::cares' => 0,
    },
    XS            => { 'cares.xs' => 'cares.c' },
    INC           => Alien::cares->cflags . " $ev{INC}",
    LIBS          => [Alien::cares->libs],
    OBJECT        => 'cares$(OBJ_EXT)',
    CONFIGURE_REQUIRES => {
        'Alien::cares'        => 0,
        'EV::MakeMaker'       => 0,
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-cares.git',
                web  => 'https://github.com/vividsnow/perl5-ev-cares',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-cares/issues',
            },
        },
    },
);
