use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my @candidates;

if (eval { require Alien::libdeflate; 1 }) {
    my $alien_libs   = eval { Alien::libdeflate->libs };
    my $alien_cflags = eval { Alien::libdeflate->cflags };
    chomp $alien_libs if defined $alien_libs;
    chomp $alien_cflags if defined $alien_cflags;
    if ($alien_libs) {
        push @candidates, [$alien_libs, $alien_cflags || ''];
    }
}

if (eval { require ExtUtils::PkgConfig; 1 }) {
    if (eval { ExtUtils::PkgConfig->atleast_version('libdeflate', '1.7') }) {
        my %pkg = eval { ExtUtils::PkgConfig->find('libdeflate') };
        if (%pkg && $pkg{libs}) {
            push @candidates, [$pkg{libs} || '', $pkg{cflags} || ''];
        }
    }
}

{
    my $ver_ok = `pkg-config --atleast-version=1.7 libdeflate 2>/dev/null`;
    if ($? == 0) {
        my $pc_libs = `pkg-config --libs libdeflate 2>/dev/null`;
        if ($? == 0 && $pc_libs =~ /\S/) {
            chomp $pc_libs;
            my $pc_cflags = `pkg-config --cflags libdeflate 2>/dev/null`;
            chomp $pc_cflags if defined $pc_cflags;
            push @candidates, [$pc_libs, $pc_cflags || ''];
        }
    }
}

push @candidates, ['-ldeflate', ''];

sub check_dependencies {
    my ($probe_libs, $probe_inc) = @_;
    require File::Temp;
    my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
    my $cfile = "$tmpdir/probe.c";
    open my $fh, '>', $cfile or return 0;
    print $fh <<'END_C';
#include <libdeflate.h>
#if defined(LIBDEFLATE_VERSION_MAJOR) && (LIBDEFLATE_VERSION_MAJOR < 1 || (LIBDEFLATE_VERSION_MAJOR == 1 && LIBDEFLATE_VERSION_MINOR < 7))
#error "libdeflate 1.7 or later is required"
#endif
#if (defined(__linux__) || defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__) || defined(_REENTRANT))
#include <pthread.h>
#define DF_HAVE_PTHREAD 1
#endif
int main(void) {
    struct libdeflate_compressor *c = libdeflate_alloc_compressor(0);
    if (c) libdeflate_free_compressor(c);
    struct libdeflate_decompressor *d = libdeflate_alloc_decompressor();
    if (d) libdeflate_free_decompressor(d);
#if defined(DF_HAVE_PTHREAD) && (defined(__GNUC__) || defined(__clang__) || defined(_MSC_VER) || (defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L && !defined(__STDC_NO_THREADS__)))
    pthread_key_t key;
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    if (pthread_mutex_lock(&mutex) || pthread_key_create(&key, 0) ||
        pthread_setspecific(key, 0) || pthread_mutex_unlock(&mutex)) return 1;
#endif
    return 0;
}
END_C
    close $fh;
    my $cc = $Config{cc};
    my $ccflags = $Config{ccflags} || '';
    my $ldflags = $Config{ldflags} || '';
    my $out = "$tmpdir/probe";
    my $cmd = "$cc $ccflags $probe_inc $cfile $ldflags $probe_libs -o $out 2>/dev/null";
    my $res = system($cmd);
    return ($res == 0);
}

my ($pthread_lib) = ($Config{libs} || '') =~ /(?:^|\s)(-l(?:pthreads?|thr))(?=\s|$)/;
$pthread_lib ||= '-lpthread';

my ($libs, $inc);
CANDIDATE:
for my $cand (@candidates) {
    for my $extra ('', " $pthread_lib") {
        my $try_libs = $cand->[0] . $extra;
        my $try_inc = $cand->[1] ? "-I. $cand->[1]" : '-I.';
        if (check_dependencies($try_libs, $try_inc)) {
            ($libs, $inc) = ($try_libs, $try_inc);
            last CANDIDATE;
        }
    }
}

if (!defined $libs) {
    print STDERR "OS unsupported: libdeflate (>= 1.7) development files and pthread support (where used) are required\n";
    exit 0;
}

my $gcc_like = $Config{gccversion} || $Config{cc} =~ /\b(?:gcc|clang|cc)\b/;
my $optimize = $Config{optimize} || '';
if ($gcc_like && $optimize !~ /-O/) {
    $optimize .= ($optimize ? ' ' : '') . '-O3';
}

my $version = MM->parse_version('lib/Deflate/Faster.pm');

WriteMakefile(
    NAME             => 'Deflate::Faster',
    VERSION_FROM     => 'lib/Deflate/Faster.pm',
    ABSTRACT_FROM    => 'lib/Deflate/Faster.pod',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    XS               => { 'Faster.xs' => 'Faster.c' },
    OBJECT           => 'Faster$(OBJ_EXT)',
    LIBS             => [$libs],
    INC              => $inc,
    ($optimize ? (OPTIMIZE => $optimize) : ()),
    depend           => {
        'Faster$(OBJ_EXT)' => 'deflate-faster-perl.c',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
        'File::Temp' => '0',
    },
    PREREQ_PM => {
        'Carp'     => '0',
        'Exporter' => '0',
        'XSLoader' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs     => {
            configure => {
                recommends => {
                    'Alien::libdeflate'   => '0.03',
                    'ExtUtils::PkgConfig' => '0',
                },
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-deflate-faster.git',
                web  => 'https://github.com/vividsnow/perl5-deflate-faster',
            },
            bugtracker => {
                web  => 'https://github.com/vividsnow/perl5-deflate-faster/issues',
            },
        },
        provides => {
            'Deflate::Faster' => {
                file    => 'lib/Deflate/Faster.pm',
                version => $version,
            },
        },
    },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
README: lib/Deflate/Faster.pod
	pod2text lib/Deflate/Faster.pod > README
MAKE_FRAG
}
