use strict;
use warnings;
use ExtUtils::MakeMaker;
use EV::MakeMaker;
use Alien::libpq;

# Pipeline mode requires libpq >= 14
my $pq_ver = Alien::libpq->version;
if (defined $pq_ver && $pq_ver =~ /^(\d+)/) {
    die "EV::Pg requires libpq >= 14 (pipeline mode). Found: $pq_ver\n"
        if $1 < 14;
}

my %ev = EV::MakeMaker::ev_args();

WriteMakefile(
    NAME          => 'EV::Pg',
    VERSION_FROM  => 'lib/EV/Pg.pm',
    ABSTRACT      => 'Async PostgreSQL client using libpq and EV',
    AUTHOR        => 'vividsnow',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.012',
    PREREQ_PM     => {
        'EV'           => '4.11',
        'Alien::libpq' => 0,
    },
    XS            => { 'Pg.xs' => 'Pg.c' },
    INC           => Alien::libpq->cflags . " $ev{INC}",
    LIBS          => [Alien::libpq->libs],
    OBJECT        => 'Pg$(OBJ_EXT)',
    CONFIGURE_REQUIRES => {
        'Alien::libpq'        => 0,
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
                url  => 'https://github.com/vividsnow/perl5-ev-pg.git',
                web  => 'https://github.com/vividsnow/perl5-ev-pg',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-pg/issues',
            },
        },
        provides => {
            'EV::Pg' => {
                file    => 'lib/EV/Pg.pm',
                version => '0.01',
            },
        },
    },
);
