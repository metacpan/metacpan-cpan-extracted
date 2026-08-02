use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
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

# --- clock_gettime: needs -lrt on old glibc (< 2.17) ---------------------
#
# backend_poll.c calls clock_gettime(CLOCK_MONOTONIC). Before glibc 2.17 that
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
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '0' },
    TEST_REQUIRES    => { 'Test::More' => '0' },
    PREREQ_PM        => {},
    # JSON helpers prefer Cpanel::JSON::XS but fall back to core JSON::PP, so
    # it is only a recommendation, not a hard requirement.
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        prereqs => { runtime => { recommends => { 'Cpanel::JSON::XS' => '0' } } },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Fetch-* Fetch.c Fetch.o Fetch.bs' },
    # Fetch.xs is a thin wrapper that INCLUDE:s the per-package fragments under
    # xs/; regenerate Fetch.c when any fragment changes. MakeMaker also does not
    # scan XS #includes, so rebuild the object when any vendored header changes
    # (edits to include/fetch/*.h always take effect).
    depend => {
        'Fetch.c'            => join(' ', glob('xs/*.xs')),
        'Fetch$(OBJ_EXT)'    => join(' ', glob('include/fetch/*.h')),
    },
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

sub probe_ssl {
    my $flags = shift;
    return probe('ssl', $flags, '#include <openssl/ssl.h>',
        'SSL_CTX *c=SSL_CTX_new(TLS_client_method()); if(c)SSL_CTX_free(c); return 0;',
        '-lssl -lcrypto');
}
