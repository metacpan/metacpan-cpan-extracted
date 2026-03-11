use strict;
use warnings;
use ExtUtils::MakeMaker;
use EV::MakeMaker;
use Alien::MariaDB;

my %ev = EV::MakeMaker::ev_args();

WriteMakefile(
    NAME          => 'EV::MariaDB',
    VERSION_FROM  => 'lib/EV/MariaDB.pm',
    ABSTRACT      => 'Async MariaDB/MySQL client using libmariadb and EV',
    AUTHOR        => 'vividsnow',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.012',
    PREREQ_PM     => {
        'EV'            => '4.11',
        'Alien::MariaDB' => 0,
    },
    XS            => { 'MariaDB.xs' => 'MariaDB.c' },
    INC           => Alien::MariaDB->cflags . " $ev{INC}",
    LIBS          => [Alien::MariaDB->libs . ' ' . ($ev{LIBS} || '')],
    OBJECT        => 'MariaDB$(OBJ_EXT)',
    CONFIGURE_REQUIRES => {
        'Alien::MariaDB'      => 0,
        'EV::MakeMaker'       => 0,
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides => {
            'EV::MariaDB' => {
                file    => 'lib/EV/MariaDB.pm',
                version => '0.01',
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-mariadb.git',
                web  => 'https://github.com/vividsnow/perl5-ev-mariadb',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-mariadb/issues',
            },
        },
    },
);
