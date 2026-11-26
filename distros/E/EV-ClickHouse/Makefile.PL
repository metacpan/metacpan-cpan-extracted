use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use EV::MakeMaker;

my %ev = EV::MakeMaker::ev_args();

my @libs;
my $extra_inc = '';
my $optimize;            # overrides EU::MM's default OPTIMIZE when set

# --with-debug rebuilds with -O0 -g -fsanitize=address,undefined and links
# the same sanitizer runtime. For author / pre-release validation only;
# the sanitizer runtime is not redistributable inside CPAN tarballs.
my $debug = grep { $_ eq '--with-debug' } @ARGV;
@ARGV = grep { $_ ne '--with-debug' } @ARGV;
if ($debug) {
    # These must go in OPTIMIZE, not INC: EU::MM's compile line is
    # `INC CCFLAGS OPTIMIZE`, so a -O0 in INC is overridden by the
    # system perl's -O2 that lives in OPTIMIZE.
    $optimize = '-O0 -g -fsanitize=address,undefined -fno-omit-frame-pointer';
    push @libs, '-fsanitize=address,undefined';
}

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

# libzstd (optional): ZSTD frames for native inserts, used only when a
# program including <zstd.h> links. --without-zstd skips it.
my $no_zstd = grep { $_ eq '--without-zstd' } @ARGV;
@ARGV = grep { $_ ne '--without-zstd' } @ARGV;
unless ($no_zstd) {
    my $zstd_cflags = `pkg-config --cflags libzstd 2>/dev/null` // '';
    my $zstd_libs   = `pkg-config --libs libzstd 2>/dev/null` // '';
    chomp($zstd_cflags, $zstd_libs);
    $zstd_libs ||= '-lzstd';
    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/z.c" or die "$dir/z.c: $!";
    print $fh "#include <zstd.h>\nint main(void) { return ZSTD_versionNumber() > 0 ? 0 : 1; }\n";
    close $fh;
    if (system("$Config{cc} $Config{ccflags} $zstd_cflags -o $dir/z $dir/z.c $Config{ldflags} $zstd_libs >/dev/null 2>&1") == 0) {
        $extra_inc .= " $zstd_cflags -DHAVE_ZSTD";
        push @libs, $zstd_libs;
    } else {
        warn "libzstd not found, building without compress_method => 'zstd'\n";
    }
}

WriteMakefile(
    NAME          => 'EV::ClickHouse',
    VERSION_FROM  => 'lib/EV/ClickHouse.pm',
    ABSTRACT      => 'Async ClickHouse client using EV',
    AUTHOR        => 'vividsnow',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.014',
    PREREQ_PM     => { 'EV' => '4.11' },
    XS            => { 'ClickHouse.xs' => 'ClickHouse.c' },
    INC           => "$ev{INC} $extra_inc",
    LIBS          => [join(' ', @libs)],
    OBJECT        => 'ClickHouse$(OBJ_EXT) lz4_unit$(OBJ_EXT)',
    ($optimize ? (OPTIMIZE => $optimize) : ()),
    # The xs/*.c sources are #include'd into ClickHouse.xs (one TU), so the
    # object file must be rebuilt when any of them changes — MakeMaker does
    # not infer #include dependencies on its own.
    depend        => {
        'ClickHouse$(OBJ_EXT)' => join(' ',
            qw(xs/codecs.c xs/io.c xs/proto_http.c xs/proto_native_build.c
               xs/proto_native_parse.c xs/queues.c xs/types.c xs/tzif.c
               xs/lz4.h xs/macros.h cityhash.h ngx_queue.h)),
        'lz4_unit$(OBJ_EXT)' => 'xs/lz4.c xs/lz4.h',
    },
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
    },
);

# Regenerate README.md from the module's POD via `make readme`. Pod::Markdown
# is a dev-time author tool; the regenerated README.md is committed alongside
# the code so end users don't need it.
sub MY::postamble {
    return <<'POSTAMBLE';
readme: lib/EV/ClickHouse.pm
	pod2markdown lib/EV/ClickHouse.pm > README.md
.PHONY: readme
POSTAMBLE
}
