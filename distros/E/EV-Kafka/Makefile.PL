use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use File::Copy qw(copy);
use EV::MakeMaker;

die "OS unsupported\n" if $^O eq "MSWin32";

unless (-f 'src/ppport.h') {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('src/ppport.h');
}

copy('src/EV__Kafka.xs', 'Kafka.xs')
    or die "Cannot copy src/EV__Kafka.xs -> Kafka.xs: $!\n";

my %ev = EV::MakeMaker::ev_args();

my @libs;
my $extra_inc = '-Isrc';

# OpenSSL (optional)
my $ssl_cflags = `pkg-config --cflags openssl 2>/dev/null`;
my $ssl_libs   = `pkg-config --libs openssl 2>/dev/null`;
chomp $ssl_cflags;
chomp $ssl_libs;

if ($ssl_libs) {
    $extra_inc .= " $ssl_cflags -DHAVE_OPENSSL";
    push @libs, $ssl_libs;
} else {
    my $test = `echo '#include <openssl/ssl.h>' | $Config{cc} -xc -fsyntax-only - 2>/dev/null; echo \$?`;
    chomp $test;
    if ($test eq '0') {
        push @libs, '-lssl -lcrypto';
        $extra_inc .= ' -DHAVE_OPENSSL';
    } else {
        warn "OpenSSL not found, building without TLS/SASL support\n";
    }
}

# LZ4 (optional, for record batch compression)
my $lz4_cflags = `pkg-config --cflags liblz4 2>/dev/null`;
my $lz4_libs   = `pkg-config --libs liblz4 2>/dev/null`;
chomp $lz4_cflags;
chomp $lz4_libs;

if ($lz4_libs) {
    $extra_inc .= " $lz4_cflags -DHAVE_LZ4";
    push @libs, $lz4_libs;
} else {
    my $test = `echo '#include <lz4.h>' | $Config{cc} -xc -fsyntax-only - 2>/dev/null; echo \$?`;
    chomp $test;
    if ($test eq '0') {
        push @libs, '-llz4';
        $extra_inc .= ' -DHAVE_LZ4';
    } else {
        warn "liblz4 not found, building without LZ4 compression\n";
    }
}

# zlib (for gzip compression)
push @libs, '-lz';
$extra_inc .= ' -DHAVE_ZLIB';

WriteMakefile(
    NAME             => 'EV::Kafka',
    VERSION_FROM     => 'lib/EV/Kafka.pm',
    ABSTRACT         => 'Async Kafka client using EV',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.012',
    XS               => { 'Kafka.xs' => 'Kafka.c' },
    INC              => "$ev{INC} $extra_inc",
    LIBS             => [join(' ', @libs)],
    OBJECT           => 'Kafka$(OBJ_EXT)',
    CONFIGURE_REQUIRES => {
        'EV::MakeMaker'       => 0,
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'EV'       => '4.11',
        'XSLoader' => '0.02',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    clean => { FILES => 'Kafka.xs Kafka.c' },
    test => { TESTS => (-d '.git' || $ENV{RELEASE_TESTING}) && -d 'xt'
                        ? 't/*.t xt/*.t' : 't/*.t' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-kafka.git',
                web  => 'https://github.com/vividsnow/perl5-ev-kafka',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-kafka/issues',
            },
        },
        no_index => {
            directory => [qw(t xt src eg bench)],
        },
    },
);
