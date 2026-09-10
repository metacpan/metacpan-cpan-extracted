use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();
use Config;

# Windows builds, with the platform's limits stated rather than discovered:
# the socket/IO surface goes through include/hyperman/hm_win.h (Winsock
# behind a CRT fd), readiness comes from the WSAPoll backend, and there is
# no fork - so one worker, no shared abuse-control arena, no detach.
# Everything Winsock needs is in ws2_32.
# cmd.exe has no /dev/null: a probe redirecting there would create a file
# and could read the wrong answer. NUL is the Windows spelling.
my $DEVNULL = $^O eq 'MSWin32' ? 'NUL' : '/dev/null';

my $win_libs = '';
if ($^O eq 'MSWin32') {
    $win_libs = '-lws2_32';
    print "Windows: Winsock + WSAPoll backend, single worker "
        . "(no fork: no pool, no shared arena, no detach).\n";
}

# --- io_uring backend: use liburing when available (Linux only) ----------
#
# The io_uring backend links against liburing rather than issuing the ring
# syscalls by hand. We detect it at configure time: pkg-config first, then a
# bare `-luring` compile probe. When neither succeeds the backend compiles to
# graceful "unavailable" stubs and auto-selection falls back to epoll/poll.
my ($uring_inc, $uring_libs) = ('', '');
if ($^O eq 'linux') {
    my ($cflags, $libs);
    if (system("pkg-config --exists liburing >$DEVNULL 2>&1") == 0) {
        chomp($cflags = `pkg-config --cflags liburing 2>$DEVNULL`);
        chomp($libs   = `pkg-config --libs liburing 2>$DEVNULL`);
        $libs ||= '-luring';
    }
    if (!$libs && probe_liburing()) {
        ($cflags, $libs) = ('', '-luring');
    }
    if ($libs) {
        $uring_inc  = " $cflags -DHM_HAVE_LIBURING";
        $uring_libs = $libs;
        print "Found liburing: io_uring backend enabled.\n";
        # Completion-mode reads need IORING_OP_RECV, which arrived in kernel
        # 5.6 / liburing 0.6. It CANNOT be tested with #ifdef: it is an enum
        # member, not a macro, so the preprocessor never sees it and a guard
        # written that way silently compiles the whole feature out while
        # every test still passes. Ask the compiler instead.
        if (probe_uring_recv($cflags || '', $libs)) {
            $uring_inc .= " -DHM_HAVE_URING_RECV";
            print "  ...IORING_OP_RECV present: completion-mode reads "
                . "available (opt in with HYPERMAN_COMPLETION=1).\n";
        } else {
            print "  ...no IORING_OP_RECV: completion-mode reads compiled out.\n";
        }
    } else {
        print "liburing not found: io_uring backend disabled "
            . "(epoll/poll remain available; install liburing-dev to enable it).\n";
    }
}

# --- TLS/HTTPS via OpenSSL (any platform with the library) ---------------
#
# A non-blocking TLS layer on the event loop; with nghttp2 also present, ALPN
# negotiates h2 over TLS. Detected like the others: pkg-config, then an
# -lssl -lcrypto compile probe. Absent, the TLS code compiles to stubs and
# `tls_cert`/`tls_key` error at runtime.
my ($tls_inc, $tls_libs) = ('', '');
{
    my ($cflags, $libs);
    if (system("pkg-config --exists openssl >$DEVNULL 2>&1") == 0) {
        chomp($cflags = `pkg-config --cflags openssl 2>$DEVNULL`);
        chomp($libs   = `pkg-config --libs openssl 2>$DEVNULL`);
        $libs ||= '-lssl -lcrypto';
    }
    if (!$libs && probe_openssl('')) {
        ($cflags, $libs) = ('', '-lssl -lcrypto');
    }
    if (!$libs) {   # homebrew keg-only path (no pkg-config on macOS)
        for my $p ('/opt/homebrew/opt/openssl', '/opt/homebrew/opt/openssl@3',
                   '/usr/local/opt/openssl', '/usr/local/opt/openssl@3') {
            next unless -d "$p/include";
            if (probe_openssl("-I$p/include -L$p/lib")) {
                ($cflags, $libs) = ("-I$p/include", "-L$p/lib -lssl -lcrypto");
                last;
            }
        }
    }
    if ($libs) {
        $tls_inc  = " $cflags -DHM_HAVE_OPENSSL";
        $tls_libs = " $libs";
        print "Found OpenSSL: TLS/HTTPS support enabled.\n";
        # Kernel TLS: the record layer moves into the kernel after the
        # handshake, which gives an HTTPS connection back the writev and
        # sendfile fast paths a plaintext one already has. Needs BOTH an
        # OpenSSL built with enable-ktls AND, at runtime, a kernel with the
        # tls ULP - so this only says the CODE can be built. Whether it
        # ENGAGES is decided per connection, and everything falls back to
        # ordinary OpenSSL writes when it does not.
        if (probe_ktls($cflags || '', $libs)) {
            $tls_inc .= " -DHM_HAVE_KTLS";
            print "  ...OpenSSL supports kernel TLS: kTLS code compiled in.\n";
        } else {
            print "  ...no kernel TLS in this OpenSSL: kTLS compiled out.\n";
        }
    } else {
        print "OpenSSL not found: TLS/HTTPS support disabled "
            . "(install libssl-dev to enable it).\n";
    }
}

# Does this OpenSSL know how to hand the record layer to the kernel?
#
# The #error lines are the whole probe. BIO_get_ktls_send is a MACRO that
# expands to a constant 0 when OpenSSL was built without kTLS, so a probe that
# merely calls it compiles and links happily against an OpenSSL that cannot do
# this at all - it would confirm the feature rather than test for it. Asking
# the preprocessor directly is the only form that can answer no.
sub probe_ktls {
    my ($cflags, $libs) = @_;
    my $dir = "hm_ktls_probe_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/probe.c", "$dir/probe", 0);
    if (open my $fh, '>', $src) {
        print $fh <<'C';
#include <openssl/ssl.h>
#include <openssl/bio.h>
#ifdef OPENSSL_NO_KTLS
#error "OpenSSL built without kernel TLS"
#endif
#ifndef SSL_OP_ENABLE_KTLS
#error "no SSL_OP_ENABLE_KTLS"
#endif
int main(int argc, char **argv) {
    SSL_CTX *c = SSL_CTX_new(TLS_server_method());
    (void)argv;
    if (c) { SSL_CTX_set_options(c, SSL_OP_ENABLE_KTLS); SSL_CTX_free(c); }
    /* referenced so it must compile and link, guarded so it never runs */
    if (argc > 99) return BIO_get_ktls_send(NULL);
    return 0;
}
C
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $cflags $src -o $bin $libs >$DEVNULL 2>&1") == 0;
    }
    unlink $src, $bin;
    rmdir $dir;
    return $ok;
}

sub probe_openssl {
    my $flags = shift;
    my $dir = "hm_tls_probe_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/probe.c", "$dir/probe", 0);
    if (open my $fh, '>', $src) {
        print $fh <<'C';
#include <openssl/ssl.h>
int main(void) {
    SSL_CTX *c = SSL_CTX_new(TLS_server_method());
    if (c) SSL_CTX_free(c);
    return 0;
}
C
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $flags $src -o $bin -lssl -lcrypto >$DEVNULL 2>&1") == 0;
    }
    unlink $src, $bin;
    rmdir $dir;
    return $ok;
}

# --- HTTP/2 via nghttp2 (any platform with the library) ------------------
#
# nghttp2 does the framing, HPACK, flow control, and stream state; we glue it
# to the loop. Detected like liburing: pkg-config, then a compile probe. When
# absent the HTTP/2 code compiles to stubs and `http2 => 1` errors at runtime.
my ($h2_inc, $h2_libs) = ('', '');
{
    my ($cflags, $libs);
    if (system("pkg-config --exists libnghttp2 >$DEVNULL 2>&1") == 0) {
        chomp($cflags = `pkg-config --cflags libnghttp2 2>$DEVNULL`);
        chomp($libs   = `pkg-config --libs libnghttp2 2>$DEVNULL`);
        $libs ||= '-lnghttp2';
    }
    if (!$libs && probe_nghttp2()) {
        ($cflags, $libs) = ('', '-lnghttp2');
    }
    if (!$libs) {   # homebrew keg-only path (no pkg-config on macOS)
        for my $p ('/opt/homebrew', '/usr/local') {
            next unless -e "$p/include/nghttp2/nghttp2.h";
            if (probe_nghttp2("-I$p/include -L$p/lib")) {
                ($cflags, $libs) = ("-I$p/include", "-L$p/lib -lnghttp2");
                last;
            }
        }
    }
    if ($libs) {
        $h2_inc  = " $cflags -DHM_HAVE_NGHTTP2";
        $h2_libs = " $libs";
        print "Found nghttp2: HTTP/2 (h2c) support enabled.\n";
    } else {
        print "nghttp2 not found: HTTP/2 support disabled "
            . "(install libnghttp2-dev to enable it).\n";
    }
}

# --- response compression via zlib (any platform with the library) -------
#
# gzip on the way out: the largest remaining win over the wire, and the one
# thing only this layer can do - it serves apps that are not Punk (the
# openapi-proxy gateway calls Hyperman->run directly) and it owns the write
# path. Detected like the others: pkg-config, then a -lz probe.
#
# The probe LINKS. A header-only check is how Punk 0.09 shipped a build that
# compiled and then failed to load with an undefined symbol; zlib.h without
# libz is exactly that shape on a minimal image.
#
# Absent zlib, hz_gzip() is a stub returning 0, `compress` is accepted and
# inert, and nothing else changes. Hyperman must stay installable without it.
my ($z_inc, $z_libs) = ('', '');
# HM_NO_ZLIB=1 forces the passthrough build. The stub path is a supported
# configuration - a smoker on a minimal image gets it whether we test it or
# not - so it has to be buildable on demand rather than only in theory.
if (!$ENV{HM_NO_ZLIB}) {
    my ($cflags, $libs);
    if (system("pkg-config --exists zlib >$DEVNULL 2>&1") == 0) {
        chomp($cflags = `pkg-config --cflags zlib 2>$DEVNULL`);
        chomp($libs   = `pkg-config --libs zlib 2>$DEVNULL`);
        $libs ||= '-lz';
    }
    if (!$libs && probe_zlib('')) {
        ($cflags, $libs) = ('', '-lz');
    }
    if (!$libs) {   # homebrew keg-only path (no pkg-config on macOS)
        for my $p ('/opt/homebrew/opt/zlib', '/usr/local/opt/zlib') {
            next unless -e "$p/include/zlib.h";
            if (probe_zlib("-I$p/include -L$p/lib")) {
                ($cflags, $libs) = ("-I$p/include", "-L$p/lib -lz");
                last;
            }
        }
    }
    if ($libs) {
        $z_inc  = " $cflags -DHM_HAVE_ZLIB";
        $z_libs = " $libs";
        print "Found zlib: response compression available "
            . "(off by default; enable with compress => 1).\n";
    } else {
        print "zlib not found: response compression disabled "
            . "(install zlib1g-dev to enable it).\n";
    }
}

# --- HTTP/3 over QUIC: ngtcp2 + ngtcp2_crypto_ossl + nghttp3 -------------
#
# Three libraries and an OpenSSL new enough to hand its TLS handshake to
# them, which is the whole reason this is one probe rather than three: any
# of them missing means no HTTP/3, so there is no partial state worth
# recording. Detected like the others - pkg-config, bare compile probe, then
# the homebrew keg-only path.
#
# It needs TLS. There is no cleartext QUIC the way there is h2c, so this
# probe does not run at all when OpenSSL was not found, and $tls_inc/$tls_libs
# are threaded into it because the crypto shim links against libssl itself.
#
# Absent any of it, hm_quic.h and hm_http3.h compile to stubs, has_http3 is
# false and `http3 => 1` errors at runtime. LibreSSL has no ngtcp2 crypto
# backend at all, so OpenBSD smokers land here by design and not by accident.
my ($q_inc, $q_libs) = ('', '');
if (!$ENV{HM_NO_HTTP3} && $tls_libs) {
    my ($cflags, $libs);
    my $pc = 'libngtcp2 libngtcp2_crypto_ossl libnghttp3';
    if (system("pkg-config --exists $pc >$DEVNULL 2>&1") == 0) {
        chomp($cflags = `pkg-config --cflags $pc 2>$DEVNULL`);
        chomp($libs   = `pkg-config --libs $pc 2>$DEVNULL`);
        $libs ||= '-lngtcp2 -lngtcp2_crypto_ossl -lnghttp3';
    }
    if ($libs && !probe_http3($cflags || '', $libs, $tls_inc, $tls_libs)) {
        # pkg-config found .pc files for a stack this OpenSSL cannot drive.
        # Believe the compiler, not the metadata.
        ($cflags, $libs) = ('', '');
    }
    if (!$libs) {
        my $bare = '-lngtcp2 -lngtcp2_crypto_ossl -lnghttp3';
        if (probe_http3('', $bare, $tls_inc, $tls_libs)) {
            ($cflags, $libs) = ('', $bare);
        }
    }
    if (!$libs) {   # homebrew keg-only path (no pkg-config on macOS)
        for my $p ('/opt/homebrew', '/usr/local') {
            next unless -e "$p/include/ngtcp2/ngtcp2.h"
                     && -e "$p/include/nghttp3/nghttp3.h";
            my $l = "-L$p/lib -lngtcp2 -lngtcp2_crypto_ossl -lnghttp3";
            if (probe_http3("-I$p/include", $l, $tls_inc, $tls_libs)) {
                ($cflags, $libs) = ("-I$p/include", $l);
                last;
            }
        }
    }
    if ($libs) {
        $q_inc  = " $cflags -DHM_HAVE_HTTP3";
        $q_libs = " $libs";
        print "Found ngtcp2 + nghttp3: HTTP/3 (QUIC) support enabled.\n";
    } else {
        print "ngtcp2/nghttp3 not found (or this OpenSSL cannot drive them): "
            . "HTTP/3 support disabled.\n";
    }
} elsif ($ENV{HM_NO_HTTP3}) {
    print "HTTP/3 support disabled by HM_NO_HTTP3.\n";
} else {
    print "HTTP/3 support disabled: it needs TLS, and OpenSSL was not found.\n";
}

# Does this stack actually work together?
#
# The three version calls are not the probe - they would link against any
# build of these libraries and tell us nothing. What is being asked is
# whether THIS OpenSSL can hand its handshake to ngtcp2:
# ngtcp2_crypto_ossl_init() is only present in a crypto shim built for the
# OSSL provider path, and SSL_set_quic_tls_cbs only exists in OpenSSL 3.5+.
# Referencing both is what makes the link fail on the stacks that cannot
# serve HTTP/3, which is the whole point - a probe that merely confirms the
# libraries exist confirms the bug instead of finding it.
sub probe_http3 {
    my ($cflags, $libs, $tlsc, $tlsl) = @_;
    my $dir = "hm_q_probe_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/probe.c", "$dir/probe", 0);
    # -DHM_HAVE_OPENSSL is a Hyperman define, not a compiler flag the probe
    # wants; strip it so the probe compiles the same way on every path.
    for ($tlsc) { defined or $_ = ''; s/-DHM_HAVE_\w+//g; }
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
                   . ">$DEVNULL 2>&1") == 0;
    }
    unlink $src, $bin;
    rmdir $dir;
    return $ok;
}

sub probe_zlib {
    my $flags = shift;
    my $dir = "hm_z_probe_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/probe.c", "$dir/probe", 0);
    if (open my $fh, '>', $src) {
        # deflateInit2_ is the real entry point behind deflateInit2, and the
        # gzip wrapper (windowBits 15|16) is the thing we actually need - a
        # probe that only calls zlibVersion() would pass against a stub.
        print $fh <<'C';
#include <zlib.h>
int main(void) {
    z_stream s;
    s.zalloc = 0; s.zfree = 0; s.opaque = 0;
    if (deflateInit2(&s, 6, Z_DEFLATED, 15 | 16, 8, Z_DEFAULT_STRATEGY) != Z_OK)
        return 1;
    deflateEnd(&s);
    return 0;
}
C
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $flags $src -o $bin -lz >$DEVNULL 2>&1") == 0;
    }
    unlink $src, $bin;
    rmdir $dir;
    return $ok;
}

# ---------------------------------------------------------------------------
# sendfile(2): three incompatible signatures, so probe each until one links
# (the feature, not the platform - the read-drip is the fallback everywhere).
my $sf_inc = '';
{
    my @flavours = (
        [ 'HM_HAVE_SENDFILE_LINUX', <<'C' ],
#include <sys/sendfile.h>
int main(void) { off_t o = 0; return (int)sendfile(1, 0, &o, (size_t)0); }
C
        [ 'HM_HAVE_SENDFILE_FREEBSD', <<'C' ],
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
int main(void) { off_t s = 0; return sendfile(0, 1, (off_t)0, (size_t)0, 0, &s, 0); }
C
        [ 'HM_HAVE_SENDFILE_MACOS', <<'C' ],
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
int main(void) { off_t l = 0; return sendfile(0, 1, (off_t)0, &l, 0, 0); }
C
    );
    for my $f (@flavours) {
        if (probe_c($f->[1])) {
            $sf_inc = " -D$f->[0]";
            print "Found sendfile(2): zero-copy file responses enabled.\n";
            last;
        }
    }
    print "sendfile(2) not usable here: file responses use the read path.\n"
        unless $sf_inc;
}

# True if the given C program compiles and links as-is.
sub probe_c {
    my ($code) = @_;
    my $dir = "hm_sf_probe_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/probe.c", "$dir/probe", 0);
    if (open my $fh, '>', $src) {
        print $fh $code;
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $src -o $bin >$DEVNULL 2>&1") == 0;
    }
    unlink $src, $bin;
    rmdir $dir;
    return $ok;
}

# True if a clock_gettime(CLOCK_MONOTONIC) program links with the given libs.
sub probe_clock_gettime {
    my ($extra) = @_;
    my $dir = "hm_rt_probe_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/probe.c", "$dir/probe", 0);
    if (open my $fh, '>', $src) {
        print $fh <<'C';
#include <time.h>
int main(void) { struct timespec ts; return clock_gettime(CLOCK_MONOTONIC, &ts); }
C
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $src -o $bin $extra >$DEVNULL 2>&1") == 0;
    }
    unlink $src, $bin;
    rmdir $dir;
    return $ok;
}

sub probe_nghttp2 {
    my ($extra) = @_;
    $extra = '' unless defined $extra;
    my $dir = "hm_h2_probe_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/probe.c", "$dir/probe", 0);
    if (open my $fh, '>', $src) {
        print $fh <<'C';
#include <nghttp2/nghttp2.h>
int main(void) {
    nghttp2_session_callbacks *cb;
    if (nghttp2_session_callbacks_new(&cb) == 0)
        nghttp2_session_callbacks_del(cb);
    return 0;
}
C
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $extra $src -o $bin -lnghttp2 >$DEVNULL 2>&1") == 0;
    }
    unlink $src, $bin;
    rmdir $dir;
    return $ok;
}

# Compile+link a tiny liburing program to confirm header and lib are usable.
# Can this liburing submit a recv? See the note at the call site for why this
# is a compile probe and not an #ifdef.
sub probe_uring_recv {
    my ($cflags, $libs) = @_;
    my $dir = "hm_urecv_probe_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/probe.c", "$dir/probe", 0);
    if (open my $fh, '>', $src) {
        print $fh <<'C';
#include <liburing.h>
int main(void) {
    struct io_uring ring;
    struct io_uring_sqe *sqe;
    char buf[16];
    if (io_uring_queue_init(8, &ring, 0) != 0) return 1;
    sqe = io_uring_get_sqe(&ring);
    if (sqe) {
        io_uring_prep_recv(sqe, 0, buf, sizeof(buf), 0);
        sqe->user_data = (unsigned long long)IORING_OP_RECV;
    }
    io_uring_queue_exit(&ring);
    return 0;
}
C
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $cflags $src -o $bin $libs >$DEVNULL 2>&1") == 0;
    }
    unlink $src, $bin;
    rmdir $dir;
    return $ok;
}

sub probe_liburing {
    my $dir  = "hm_uring_probe_$$";
    mkdir $dir or return 0;
    my $src  = "$dir/probe.c";
    my $bin  = "$dir/probe";
    my $ok   = 0;
    if (open my $fh, '>', $src) {
        print $fh <<'C';
#include <liburing.h>
int main(void) {
    struct io_uring ring;
    if (io_uring_queue_init(8, &ring, 0) == 0) io_uring_queue_exit(&ring);
    return 0;
}
C
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $src -o $bin -luring >$DEVNULL 2>&1") == 0;
    }
    unlink $src, $bin;
    rmdir $dir;
    return $ok;
}

# --- clock_gettime: needs -lrt on old glibc (< 2.17) ---------------------
#
# backend_poll.c calls clock_gettime(CLOCK_MONOTONIC). On glibc before 2.17
# that symbol lives in librt, not libc, so the .so loads with
# "undefined symbol: clock_gettime" unless we link -lrt. Newer glibc folds it
# into libc, and macOS/BSD have no librt at all, so only add it when a link
# probe genuinely needs it.
my $rt_libs = '';
if (!probe_clock_gettime('') && probe_clock_gettime('-lrt')) {
    $rt_libs = '-lrt';
    print "clock_gettime needs -lrt (old glibc): linking it.\n";
}

# --- ExtUtils::Depends: provide the public C ABI --------------------------
# Hyperman is a PROVIDER: it installs hm_abi.h (the versioned function-pointer
# table consumers resolve at runtime via Hyperman::_abi_ptr) so dependents
# like DBIx::Loop reach the header without vendoring a copy. save_config
# writes Install/Files.pm; consumers then ExtUtils::Depends->new(X,'Hyperman').
my $pkg = ExtUtils::Depends->new('Hyperman');
$pkg->set_inc('-Iinclude/hyperman');
$pkg->install('include/hyperman/hm_abi.h');

# THE BUS IS PUBLISHED TOO, and under a `hyperman/` subdirectory.
#
# A consumer that wants the cross-worker live tail includes
# "hyperman/hm_bus.h" - Punk::Observe does - and hm_bus.h in turn includes
# "hm_atomic.h" relative to its own directory. So both have to land together
# in a directory of that name, or the include resolves and its dependency
# does not.
#
# NOT through ExtUtils::Depends' install(), which takes the basename and
# would flatten both into Install/ - where "hyperman/hm_bus.h" does not
# resolve at all. The PM entries are written out instead.
#
# Publishing only hm_abi.h was the whole of the bug this fixes: a consumer
# with Hyperman correctly installed found no hm_bus.h, silently fell back to
# an in-process tail, and a live tail on a prefork pool then showed whichever
# quarter of the traffic the answering worker happened to hold.
for my $h (qw(hm_bus.h hm_atomic.h)) {
    $pkg->add_pm("include/hyperman/$h",
                 '$(INST_ARCHLIB)/$(FULLEXT)/Install/hyperman/' . $h);
}

mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %DEP = $pkg->get_makefile_vars;
my $dep_inc = delete $DEP{INC};
# Merge (don't clobber) LIBS - EU::Depends returns an empty LIBS that would
# otherwise wipe out -lssl/-lcrypto/-lnghttp2/-luring and silently disable
# TLS/h2/io_uring. LDFROM likewise defaults to $(OBJECT); drop EU::Depends'.
my $dep_libs = delete $DEP{LIBS};
delete $DEP{LDFROM};

# EU::Depends' PM map (installing hm_abi.h + Files.pm) replaces MakeMaker's
# auto-detected PM, so re-add the module's own files. .pod as well as .pm:
# MakeMaker would have installed both, and a standalone page (Windows.pod)
# is silently dropped from the distribution if this only matches .pm.
File::Find::find(sub {
    return unless /\.p(?:m|od)\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $DEP{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

my %WriteMakefileArgs = (
    NAME             => 'Hyperman',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Hyperman.pm',
    ABSTRACT_FROM    => 'lib/Hyperman.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    OBJECT           => 'Hyperman$(OBJ_EXT)',
    INC              => join(' ', grep { defined && length }
                            '-Iinclude/hyperman' . $uring_inc . $h2_inc . $tls_inc . $sf_inc . $z_inc . $q_inc,
                            $dep_inc),
    LIBS             => [ join(' ', grep { defined && length } $uring_libs, $h2_libs, $tls_libs, $z_libs, $q_libs, $rt_libs, $win_libs, $dep_libs) ],
    # MakeMaker tracks neither include/*.h nor the xs/*.xs pulled in with
    # INCLUDE:, so every one of them has to be listed here or a rebuild
    # silently tests stale objects. Both lists were incomplete: xs/bus.xs is
    # INCLUDE:d by Hyperman.xs:87 and was missing, as were six headers
    # Hyperman.xs includes. Keep them in the order the files are included.
    depend           => {
        'Hyperman.c' => 'xs/hyperman.xs xs/future.xs xs/loop.xs '
                      . 'xs/writer.xs xs/event.xs xs/abi.xs xs/bus.xs '
                      . 'xs/quic.xs',
        'Hyperman$(OBJ_EXT)' =>
            'include/hyperman/hyperman.h include/hyperman/hm_core.h '
          . 'include/hyperman/hm_compat.h '
          . 'include/hyperman/hm_future.h include/hyperman/backend_kqueue.c '
          . 'include/hyperman/backend_epoll.c include/hyperman/backend_poll.c '
          . 'include/hyperman/backend_wsapoll.c '
          . 'include/hyperman/backend_iouring.c include/hyperman/hm_http2.h '
          . 'include/hyperman/hm_tls.h include/hyperman/hm_abi.h '
          . 'include/hyperman/hm_win.h include/hyperman/hm_abi_impl.h '
          . 'include/hyperman/hm_stream.h '
          . 'include/hyperman/hm_quic.h include/hyperman/hm_http3.h '
          . 'include/hyperman/hm_compress.h include/hyperman/hm_parse.h '
          . 'include/hyperman/hm_ratelimit.h '
          . 'include/hyperman/hm_atomic.h include/hyperman/hm_bus.h '
          . 'include/hyperman/hm_bus_perl.h '
          . 'include/hyperman/hm_workerhook.h '
          . 'include/hyperman/hm_workerhook_perl.h',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    	'Plack::Test::Suite' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Hyperman-* Install/Files.pm' },
    %DEP,   # ExtUtils::Depends: PM map (installs hm_abi.h + Files.pm + our .pm)
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
