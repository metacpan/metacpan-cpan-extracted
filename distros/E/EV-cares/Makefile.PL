use strict;
use warnings;
use ExtUtils::MakeMaker;
use EV::MakeMaker;
use Alien::cares;

# servers() uses ares_get_servers_csv, which needs c-ares >= 1.24.
my $cares_version = Alien::cares->version;
if (defined $cares_version && length $cares_version) {
    my @v = split /\./, $cares_version;
    # per-field numeric compare: "1.7.2" must sort below "1.24"
    my $too_old = ($v[0] // 0) < 1
        || (($v[0] // 0) == 1 && ($v[1] // 0) < 24);
    die "EV::cares requires c-ares >= 1.24, but Alien::cares provides"
        . " $cares_version\n"
        if $too_old;
} else {
    warn "EV::cares: could not determine the c-ares version from"
        . " Alien::cares; continuing, but c-ares >= 1.24 is required\n";
}

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
        'Socket'       => '1.94',
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
        no_index => {
            directory => ['eg', 't'],
        },
    },
);
