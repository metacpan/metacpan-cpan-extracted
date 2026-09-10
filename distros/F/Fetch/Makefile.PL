use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();
use Config;

# Fetch vendors its own C core (event loop backends, Future, client TLS, and
# nghttp2 client glue) so it stands alone. Optional C libraries are detected at
# configure time exactly like Hyperman: pkg-config first, then a compile probe.
# When a library is absent the matching code compiles to graceful stubs
# (HTTP/1.1 keeps working without OpenSSL/nghttp2).

my $DEFINE = '';
my $LIBS   = '';
my $INC    = '-Iinclude';

# --- event backend: io_uring (Linux, optional) ---------------------------
if ($^O eq 'linux') {
    my ($cflags, $libs);
    if (system('pkg-config --exists liburing >/dev/null 2>&1') == 0) {
        chomp($cflags = `pkg-config --cflags liburing 2>/dev/null`);
        chomp($libs   = `pkg-config --libs liburing 2>/dev/null`);
        $libs ||= '-luring';
    }
    if (!$libs && probe('liburing', '', '#include <liburing.h>',
                        'struct io_uring r; (void)r; return 0;', '-luring')) {
        ($cflags, $libs) = ('', '-luring');
    }
    if ($libs) {
        $DEFINE .= ' -DHM_HAVE_LIBURING';   # macro the vendored backend uses
        $INC    .= " $cflags";
        $LIBS   .= " $libs";
        print "Found liburing: io_uring backend enabled.\n";
    } else {
        print "liburing not found: io_uring disabled (epoll/poll remain).\n";
    }
}

# --- OpenSSL (TLS/HTTPS + ALPN for h2) ------------------------------------
# The flags are kept: the QUIC probe below links against libssl itself, so it
# has to be given the same OpenSSL this build found rather than whichever one
# the compiler would pick on its own.
my ($tls_inc, $tls_libs) = ('', '');
{
    my ($cflags, $libs);
    if (system('pkg-config --exists openssl >/dev/null 2>&1') == 0) {
        chomp($cflags = `pkg-config --cflags openssl 2>/dev/null`);
        chomp($libs   = `pkg-config --libs openssl 2>/dev/null`);
        $libs ||= '-lssl -lcrypto';
    }
    if (!$libs && probe_ssl('')) { ($cflags, $libs) = ('', '-lssl -lcrypto') }
    if (!$libs) {   # homebrew keg-only path (no pkg-config on macOS)
        for my $p ('/opt/homebrew/opt/openssl', '/opt/homebrew/opt/openssl@3',
                   '/usr/local/opt/openssl', '/usr/local/opt/openssl@3') {
            next unless -d "$p/include";
            if (probe_ssl("-I$p/include -L$p/lib")) {
                ($cflags, $libs) = ("-I$p/include", "-L$p/lib -lssl -lcrypto");
                last;
            }
        }
    }
    if ($libs) {
        $DEFINE .= ' -DFT_HAVE_OPENSSL';
        $INC    .= " $cflags";
        $LIBS   .= " $libs";
        ($tls_inc, $tls_libs) = ($cflags || '', $libs);
        print "Found OpenSSL: HTTPS/TLS support enabled.\n";
    } else {
        print "OpenSSL not found: HTTPS disabled (install libssl-dev).\n";
    }
}

# --- nghttp2 (HTTP/2 client) ---------------------------------------------
{
    my ($cflags, $libs);
    if (system('pkg-config --exists libnghttp2 >/dev/null 2>&1') == 0) {
        chomp($cflags = `pkg-config --cflags libnghttp2 2>/dev/null`);
        chomp($libs   = `pkg-config --libs libnghttp2 2>/dev/null`);
        $libs ||= '-lnghttp2';
    }
    if (!$libs && probe('nghttp2', '', '#include <nghttp2/nghttp2.h>',
                        'nghttp2_session_callbacks *c=0; (void)c; return 0;',
                        '-lnghttp2')) {
        ($cflags, $libs) = ('', '-lnghttp2');
    }
    if (!$libs) {   # homebrew path (no pkg-config on macOS)
        for my $p ('/opt/homebrew', '/usr/local') {
            next unless -e "$p/include/nghttp2/nghttp2.h";
            if (probe('nghttp2', "-I$p/include -L$p/lib",
                      '#include <nghttp2/nghttp2.h>',
                      'nghttp2_session_callbacks *c=0; (void)c; return 0;',
                      '-lnghttp2')) {
                ($cflags, $libs) = ("-I$p/include", "-L$p/lib -lnghttp2");
                last;
            }
        }
    }
    if ($libs) {
        $DEFINE .= ' -DFT_HAVE_NGHTTP2';
        $INC    .= " $cflags";
        $LIBS   .= " $libs";
        print "Found nghttp2: HTTP/2 support enabled.\n";
    } else {
        print "nghttp2 not found: HTTP/2 disabled (install libnghttp2-dev).\n";
    }
}

# --- HTTP/3 over QUIC: ngtcp2 + ngtcp2_crypto_ossl + nghttp3 -------------
#
# The same three libraries, the same all-or-none rule and the same
# link-not-compile requirement as the server side (Hyperman's Makefile.PL),
# because it is the same stack and a client that disagreed with the server
# about whether it is usable would be worse than one without it.
#
# It needs TLS: there is no cleartext QUIC the way there is h2c, so the probe
# does not run at all without OpenSSL, and the OpenSSL flags found above are
# threaded through it because the crypto shim links against libssl.
#
# Absent any of it, ft_h3.h compiles to stubs, Fetch::_h3_available is false
# and an h3 attempt falls back to TCP. LibreSSL has no ngtcp2 crypto backend,
# so OpenBSD smokers land here by design.
if (!$ENV{FT_NO_HTTP3} && $tls_libs) {
    my ($cflags, $libs);
    my $pc = 'libngtcp2 libngtcp2_crypto_ossl libnghttp3';
    if (system("pkg-config --exists $pc >/dev/null 2>&1") == 0) {
        chomp($cflags = `pkg-config --cflags $pc 2>/dev/null`);
        chomp($libs   = `pkg-config --libs $pc 2>/dev/null`);
        $libs ||= '-lngtcp2 -lngtcp2_crypto_ossl -lnghttp3';
    }
    # pkg-config can find .pc files for a stack this OpenSSL cannot drive.
    # Believe the compiler, not the metadata.
    if ($libs && !probe_h3($cflags || '', $libs, $tls_inc, $tls_libs)) {
        ($cflags, $libs) = ('', '');
    }
    if (!$libs) {
        my $bare = '-lngtcp2 -lngtcp2_crypto_ossl -lnghttp3';
        ($cflags, $libs) = ('', $bare)
            if probe_h3('', $bare, $tls_inc, $tls_libs);
    }
    if (!$libs) {   # homebrew keg-only path (no pkg-config on macOS)
        for my $p ('/opt/homebrew', '/usr/local') {
            next unless -e "$p/include/ngtcp2/ngtcp2.h"
                     && -e "$p/include/nghttp3/nghttp3.h";
            my $l = "-L$p/lib -lngtcp2 -lngtcp2_crypto_ossl -lnghttp3";
            if (probe_h3("-I$p/include", $l, $tls_inc, $tls_libs)) {
                ($cflags, $libs) = ("-I$p/include", $l);
                last;
            }
        }
    }
    if ($libs) {
        $DEFINE .= ' -DFT_HAVE_QUIC';
        $INC    .= " $cflags";
        $LIBS   .= " $libs";
        print "Found ngtcp2 + nghttp3: HTTP/3 support enabled.\n";
    } else {
        print "ngtcp2/nghttp3 not found (or this OpenSSL cannot drive them): "
            . "HTTP/3 disabled.\n";
    }
} elsif ($ENV{FT_NO_HTTP3}) {
    print "HTTP/3 disabled by FT_NO_HTTP3.\n";
} else {
    print "HTTP/3 disabled: it needs TLS, and OpenSSL was not found.\n";
}

# --- pthreads: name resolution off the loop thread (ft_dns.h) ------------
#
# getaddrinfo is the one call in a request that blocks, and it blocks the
# whole loop rather than the one connection - so it runs on a thread of its
# own. The thread touches no Perl, so this has nothing to do with whether
# perl itself is threaded; it is the C library's pthreads and nothing more.
#
# The probe must LINK. On glibc 2.34+ and on macOS the symbols are in libc
# and no flag is needed; on older glibc and on some BSDs they are in
# libpthread, and a compile-only probe would find the header either way and
# ship a .so that fails to load. Without it Fetch resolves inline exactly as
# it always did - slower under concurrency, never wrong.
unless ($^O eq 'MSWin32') {
    my $inc  = "#include <pthread.h>\n#include <netdb.h>";
    my $body = 'pthread_t t; pthread_attr_t a; pthread_attr_init(&a); '
             . 'return pthread_create(&t, &a, 0, 0) == 0;';
    if (probe('pthread', '', $inc, $body, '')) {
        $DEFINE .= ' -DFT_HAVE_PTHREAD';
        print "pthreads: name resolution runs off the loop thread.\n";
    }
    elsif (probe('pthread', '', $inc, $body, '-lpthread')) {
        $DEFINE .= ' -DFT_HAVE_PTHREAD';
        $LIBS   .= ' -lpthread';
        print "pthreads (-lpthread): name resolution runs off the loop thread.\n";
    }
    else {
        print "pthreads not found: name resolution stays inline.\n";
    }
}

# --- clock_gettime: needs -lrt on old glibc (< 2.17) ---------------------
#
# ft_monotonic (ft_win.h) calls clock_gettime(CLOCK_MONOTONIC). Before glibc 2.17 that
# symbol lives in librt, so the .so loads with "undefined symbol:
# clock_gettime" unless we link -lrt. Newer glibc folds it into libc, and
# macOS/BSD have no librt, so only add it when a link probe needs it.
{
    my $inc = '#include <time.h>';
    my $body = 'struct timespec ts; return clock_gettime(CLOCK_MONOTONIC, &ts);';
    if (!probe('rt', '', $inc, $body, '') && probe('rt', '', $inc, $body, '-lrt')) {
        $LIBS .= ' -lrt';
        print "clock_gettime needs -lrt (old glibc): linking it.\n";
    }
}

# --- native Windows: link Winsock (last, so it resolves openssl's refs) ---
# The socket layer maps onto Winsock (ft_win.h) and the readiness backend is
# select() (backend_select.c); both need ws2_32, and OpenSSL depends on it too,
# so it goes at the end of the link line. Everything else (the fork-free
# client, non-blocking IO, timers) is portable. Cygwin looks like Unix and is
# left alone.
if ($^O eq 'MSWin32') {
    $LIBS .= ' -lws2_32';
}

# --- ExtUtils::Depends -----------------------------------------------------
# Fetch is BOTH a consumer (of File::Raw::JSON's frj_abi, used by ft_json.h to
# decode/encode JSON in C) and a provider (it installs fetch_abi.h so dependents
# like JSON::Schema::Fast reach Fetch's ABI without vendoring a copy).
my $pkg;
eval { $pkg = ExtUtils::Depends->new('Fetch', 'File::Raw::JSON'); 1 };
if (!$pkg) {
    die "Cannot find the File::Raw::JSON dependency.\n"
      . "Install File::Raw::JSON 0.05+, or place it as a sibling directory.\n"
        unless -d '../File-Raw-JSON/include';
    $pkg = ExtUtils::Depends->new('Fetch');            # provider only
    $INC .= ' -I../File-Raw-JSON/include';             # frj_abi.h fallback
}
$pkg->install('include/fetch/fetch_abi.h');            # provide fetch_abi.h
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep = $pkg->get_makefile_vars;
$INC  .= ' ' . delete $dep{INC} if $dep{INC};          # merge frj + provider inc
# Merge (don't clobber) LIBS - EU::Depends returns an empty LIBS that would
# otherwise wipe out Fetch's own -lssl/-lcrypto/-lnghttp2 and silently break
# TLS/HTTP2. LDFROM likewise defaults to $(OBJECT); drop EU::Depends' copy.
$LIBS  = join ' ', grep { defined && length } $LIBS, delete $dep{LIBS};
delete $dep{LDFROM};

# EU::Depends' PM map (installing fetch_abi.h + Files.pm) replaces MakeMaker's
# auto-detected PM, so re-add the module's own .pm files.
File::Find::find(sub {
    return unless /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

my %WriteMakefileArgs = (
    NAME             => 'Fetch',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Fetch.pm',
    ABSTRACT_FROM    => 'lib/Fetch.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    macro            => { TARFLAGS => '--format=ustar -c -v -f' },
    INC              => $INC,
    DEFINE           => $DEFINE,
    LIBS             => [$LIBS],
    XS               => { 'Fetch.xs' => 'Fetch.c' },
    OBJECT           => 'Fetch$(OBJ_EXT)',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw::JSON'     => '0.05',
    },
    TEST_REQUIRES    => { 'Test::More' => '0' },
    PREREQ_PM        => {
        'File::Raw::JSON' => '0.05',   # JSON encode/decode via its C ABI
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Fetch-* Fetch.c Fetch.o Fetch.bs Install/Files.pm' },
    # Fetch.xs is a thin wrapper that INCLUDE:s the per-package fragments under
    # xs/; regenerate Fetch.c when any fragment changes. MakeMaker also does not
    # scan XS #includes, so rebuild the object when any vendored header changes
    # (edits to include/fetch/*.h always take effect).
    depend => {
        'Fetch.c'            => join(' ', glob('xs/*.xs')),
        'Fetch$(OBJ_EXT)'    => join(' ', glob('include/fetch/*.h')),
    },
    %dep,   # ExtUtils::Depends: TYPEMAPS + PM (installs fetch_abi.h + our .pm)
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}
delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

# Generic compile probe: true if the snippet builds+links with $libs.
sub probe {
    my ($name, $flags, $includes, $body, $libs) = @_;
    my $dir = "ft_probe_${name}_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/p.c", "$dir/p", 0);
    if (open my $fh, '>', $src) {
        print $fh "$includes\nint main(void){ $body }\n";
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $flags $src -o $bin $libs >/dev/null 2>&1") == 0;
    }
    unlink $src, $bin; rmdir $dir;
    return $ok;
}

# Does this QUIC stack actually work with this OpenSSL?
#
# The version calls are not the probe - they link against any build of these
# libraries and say nothing. What is being asked is whether THIS OpenSSL can
# hand its handshake to ngtcp2: ngtcp2_crypto_ossl_init exists only in a
# crypto shim built for the OSSL provider path, and SSL_set_quic_tls_cbs only
# in OpenSSL 3.5+. Referencing both is what makes the link fail on a stack
# that cannot speak HTTP/3 - a probe that merely confirms the libraries are
# installed confirms the bug instead of finding it.
sub probe_h3 {
    my ($cflags, $libs, $tlsc, $tlsl) = @_;
    my $dir = "ft_probe_h3_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/p.c", "$dir/p", 0);
    for ($tlsc) { defined or $_ = ''; s/-DFT_HAVE_\w+//g; }
    $tlsl = '' unless defined $tlsl;
    if (open my $fh, '>', $src) {
        print $fh <<'C';
#include <ngtcp2/ngtcp2.h>
#include <ngtcp2/ngtcp2_crypto.h>
#include <ngtcp2/ngtcp2_crypto_ossl.h>
#include <nghttp3/nghttp3.h>
#include <openssl/ssl.h>
int main(void) {
    void *p;
    if (ngtcp2_crypto_ossl_init() != 0) return 1;
    p = (void *)&SSL_set_quic_tls_cbs;
    if (!p) return 1;
    if (!ngtcp2_version(0) || !nghttp3_version(0)) return 1;
    return 0;
}
C
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $cflags $tlsc $src -o $bin $libs $tlsl "
                   . ">/dev/null 2>&1") == 0;
    }
    unlink $src, $bin;
    rmdir $dir;
    return $ok;
}

sub probe_ssl {
    my $flags = shift;
    return probe('ssl', $flags, '#include <openssl/ssl.h>',
        'SSL_CTX *c=SSL_CTX_new(TLS_client_method()); if(c)SSL_CTX_free(c); return 0;',
        '-lssl -lcrypto');
}
