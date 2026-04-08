use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Copy qw(copy);
use EV::MakeMaker '$installsitearch';

die "OS unsupported\n" if $^O eq "MSWin32";

# Generate ppport.h if needed
unless (-f 'src/ppport.h') {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('src/ppport.h');
}

# Copy XS source to top-level for MakeMaker
copy('src/EV__Memcached.xs', 'Memcached.xs')
    or die "Cannot copy src/EV__Memcached.xs -> Memcached.xs: $!\n";

my @inc = ('-Isrc', "-I$installsitearch/EV", "-I$installsitearch");

WriteMakefile(
    NAME             => 'EV::Memcached',
    VERSION_FROM     => 'lib/EV/Memcached.pm',
    ABSTRACT_FROM    => 'lib/EV/Memcached.pm',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.012000',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'EV::MakeMaker'       => 0,
    },
    PREREQ_PM => {
        'EV'       => '4.11',
        'XSLoader' => '0.02',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },

    INC    => join(' ', @inc),
    DEFINE => '',
    LIBS   => [''],

    clean => { FILES => 'Memcached.xs Memcached.c' },

    test => { TESTS => (-d '.git' || $ENV{RELEASE_TESTING}) && -d 'xt'
                        ? 't/*.t xt/*.t' : 't/*.t' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-memcached.git',
                web  => 'https://github.com/vividsnow/perl5-ev-memcached',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-memcached/issues',
            },
        },
        no_index => {
            directory => [qw(t xt src)],
        },
    },
);
