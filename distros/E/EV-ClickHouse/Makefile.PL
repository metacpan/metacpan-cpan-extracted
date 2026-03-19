use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use EV::MakeMaker;

my %ev = EV::MakeMaker::ev_args();

my @libs;
my $extra_inc = '';

# OpenSSL (optional)
my $ssl_cflags = `pkg-config --cflags openssl 2>/dev/null`;
my $ssl_libs   = `pkg-config --libs openssl 2>/dev/null`;
chomp $ssl_cflags;
chomp $ssl_libs;

if ($ssl_libs) {
    $extra_inc .= " $ssl_cflags";
    push @libs, $ssl_libs;
    $extra_inc .= ' -DHAVE_OPENSSL';
} else {
    # try without pkg-config
    my $test = `echo '#include <openssl/ssl.h>' | $Config{cc} -xc -fsyntax-only - 2>/dev/null; echo \$?`;
    chomp $test;
    if ($test eq '0') {
        push @libs, '-lssl -lcrypto';
        $extra_inc .= ' -DHAVE_OPENSSL';
    } else {
        warn "OpenSSL not found, building without TLS support\n";
    }
}

# zlib
push @libs, '-lz';

# lz4 (for native protocol compression)
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
        warn "liblz4 not found, building without native protocol compression\n";
    }
}

WriteMakefile(
    NAME          => 'EV::ClickHouse',
    VERSION_FROM  => 'lib/EV/ClickHouse.pm',
    ABSTRACT      => 'Async ClickHouse client using EV',
    AUTHOR        => 'vividsnow',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.012',
    PREREQ_PM     => { 'EV' => '4.11' },
    XS            => { 'ClickHouse.xs' => 'ClickHouse.c' },
    INC           => "$ev{INC} $extra_inc",
    LIBS          => [join(' ', @libs)],
    OBJECT        => 'ClickHouse$(OBJ_EXT)',
    CONFIGURE_REQUIRES => {
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
                url  => 'https://github.com/vividsnow/perl5-ev-clickhouse.git',
                web  => 'https://github.com/vividsnow/perl5-ev-clickhouse',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-clickhouse/issues',
            },
        },
        provides => {
            'EV::ClickHouse' => {
                file    => 'lib/EV/ClickHouse.pm',
                version => '0.01',
            },
        },
    },
);
