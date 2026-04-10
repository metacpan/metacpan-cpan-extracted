use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Copy qw(copy);
use Config;
use EV::MakeMaker '$installsitearch';

die "OS unsupported\n" if $^O eq "MSWin32";

unless (-f 'src/ppport.h') {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('src/ppport.h');
}

copy('src/EV__Nats.xs', 'Nats.xs')
    or die "Cannot copy src/EV__Nats.xs -> Nats.xs: $!\n";

my @inc = ('-Isrc', "-I$installsitearch/EV", "-I$installsitearch");
my @libs;
my $define = '';

# OpenSSL (optional TLS)
my $ssl_cflags = `pkg-config --cflags openssl 2>/dev/null`;
my $ssl_libs   = `pkg-config --libs openssl 2>/dev/null`;
chomp $ssl_cflags;
chomp $ssl_libs;

if ($ssl_libs) {
    push @inc, $ssl_cflags;
    push @libs, $ssl_libs;
    $define .= ' -DHAVE_OPENSSL';
    print "OpenSSL: yes (pkg-config)\n";
} else {
    my $test = `echo '#include <openssl/ssl.h>' | $Config{cc} -xc -fsyntax-only - 2>/dev/null; echo \$?`;
    chomp $test;
    if ($test eq '0') {
        push @libs, '-lssl -lcrypto';
        $define .= ' -DHAVE_OPENSSL';
        print "OpenSSL: yes (header probe)\n";
    } else {
        print "OpenSSL: not found, building without TLS\n";
    }
}

WriteMakefile(
    NAME             => 'EV::Nats',
    VERSION_FROM     => 'lib/EV/Nats.pm',
    ABSTRACT_FROM    => 'lib/EV/Nats.pm',
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

    INC      => join(' ', @inc),
    DEFINE   => $define,
    LIBS     => [join(' ', @libs)],
    TYPEMAPS => ['typemap'],

    clean => { FILES => 'Nats.xs Nats.c' },

    test => { TESTS => (-d '.git' || $ENV{RELEASE_TESTING}) && -d 'xt'
                        ? 't/*.t xt/*.t' : 't/*.t' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-nats.git',
                web  => 'https://github.com/vividsnow/perl5-ev-nats',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-nats/issues',
            },
        },
        no_index => {
            directory => [qw(t xt src)],
        },
    },
);
