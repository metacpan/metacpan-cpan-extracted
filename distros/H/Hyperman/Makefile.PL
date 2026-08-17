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
    } else {
        print "OpenSSL not found: TLS/HTTPS support disabled "
            . "(install libssl-dev to enable it).\n";
    }
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
                            '-Iinclude/hyperman' . $uring_inc . $h2_inc . $tls_inc . $sf_inc,
                            $dep_inc),
    LIBS             => [ join(' ', grep { defined && length } $uring_libs, $h2_libs, $tls_libs, $rt_libs, $win_libs, $dep_libs) ],
    depend           => {
        'Hyperman.c' => 'xs/hyperman.xs xs/future.xs xs/loop.xs '
                      . 'xs/writer.xs xs/event.xs xs/abi.xs',
        'Hyperman$(OBJ_EXT)' =>
            'include/hyperman/hyperman.h include/hyperman/hm_core.h '
          . 'include/hyperman/hm_future.h include/hyperman/backend_kqueue.c '
          . 'include/hyperman/backend_epoll.c include/hyperman/backend_poll.c '
          . 'include/hyperman/backend_wsapoll.c '
          . 'include/hyperman/backend_iouring.c include/hyperman/hm_http2.h '
          . 'include/hyperman/hm_tls.h include/hyperman/hm_abi.h '
          . 'include/hyperman/hm_win.h include/hyperman/hm_abi_impl.h',
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
