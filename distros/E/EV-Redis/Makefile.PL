use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use File::Copy qw(copy);
use File::Which qw(which);
use EV::MakeMaker '$installsitearch';

die "OS unsupported\n" if $^O eq "MSWin32";

unless (-f 'src/ppport.h') {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('src/ppport.h');
}

copy('src/EV__Redis.xs', 'Redis.xs')
    or die "Cannot copy src/EV__Redis.xs -> Redis.xs: $!\n";

sub _detect_openssl {
    if (defined $ENV{OPENSSL_PREFIX}) {
        my $p = $ENV{OPENSSL_PREFIX};
        return $p if -d "$p/include/openssl";
        warn "OPENSSL_PREFIX=$p but no include/openssl found\n";
        return undef;
    }
    if (system("pkg-config --exists openssl 2>/dev/null") == 0) {
        my $cflags = `pkg-config --cflags openssl 2>/dev/null`;
        my $libs   = `pkg-config --libs openssl 2>/dev/null`;
        chomp($cflags, $libs);
        return { cflags => $cflags, libs => $libs };
    }
    if ($^O eq 'darwin') {
        for my $path ('/opt/homebrew/opt/openssl', '/usr/local/opt/openssl') {
            return $path if -d "$path/include/openssl";
        }
    }
    for my $inc ('/usr/include', '/usr/local/include') {
        return { cflags => '', libs => '-lssl -lcrypto' } if -f "$inc/openssl/ssl.h";
    }
    return undef;
}

sub _has_libssl {
    my ($dir) = @_;
    opendir my $dh, $dir or return 0;
    my $found = grep { /^libssl\./ } readdir $dh;
    closedir $dh;
    return $found;
}

my $want_ssl = $ENV{EV_REDIS_SSL};
my ($has_ssl, $ssl_cflags, $ssl_libs, $ssl_detected) = (0, '', '', undef);

if (!defined $want_ssl || $want_ssl) {
    $ssl_detected = _detect_openssl();
    if ($ssl_detected) {
        $has_ssl = 1;
        if (ref $ssl_detected eq 'HASH') {
            ($ssl_cflags, $ssl_libs) = ($ssl_detected->{cflags}, $ssl_detected->{libs});
        } else {
            # some prefixes (e.g. --libdir=lib64 builds) keep libraries in lib64
            my $libdir = 'lib';
            $libdir = 'lib64'
                if !_has_libssl("$ssl_detected/lib")
                && _has_libssl("$ssl_detected/lib64");
            ($ssl_cflags, $ssl_libs) = ("-I$ssl_detected/include",
                "-L$ssl_detected/$libdir -lssl -lcrypto");
        }
    } elsif ($want_ssl) {
        die "EV_REDIS_SSL=1 but OpenSSL not found. Install OpenSSL development headers or set OPENSSL_PREFIX.\n";
    }
}

print $has_ssl
    ? "Building with TLS support\n"
    : "Building without TLS support (set EV_REDIS_SSL=1 to force)\n";

die <<'EOM' unless -f 'deps/hiredis/Makefile';
deps/hiredis is missing or empty. This distribution bundles hiredis as a
git submodule; run:

    git submodule update --init

and then re-run: perl Makefile.PL
EOM

# every hunk of the patch carries its revision marker: a partly applied or
# older patch leaves a count that differs from the patch's own
sub _patch_markers {
    my ($file, $added_only) = @_;
    open my $fh, '<', $file or die "Cannot read $file: $!\n";
    my $n = 0;
    while (<$fh>) {
        $n++ if (!$added_only || /^\+/) && /local patch \(EV::Redis\/3\)/;
    }
    return $n;
}

{
    my $patch = 'deps/hiredis-protocol-errors.patch';
    my $async = 'deps/hiredis/async.c';
    die "Local hiredis patch $patch is missing from this distribution.\n" unless -f $patch;
    my $want = _patch_markers($patch, 1);
    my $have = _patch_markers($async);
    if (!$have) {
        my $patch_bin = which('patch')
            or die "The 'patch' utility is required to build (it applies $patch).\n";
        print "Applying $patch\n";
        system($patch_bin, '-p1', '-i', $patch) == 0
            or die "Failed to apply $patch: restore $async"
            . " (git -C deps/hiredis checkout async.c) and see the patch header.\n";
        $have = _patch_markers($async);
    }
    $have == $want
        or die "$async holds $have of the $want marked changes of $patch: restore it"
        . " (git -C deps/hiredis checkout async.c) and re-run perl Makefile.PL.\n";
}

my $make = $Config{make};
if (`$make --version 2>&1` !~ /GNU Make/) {
    $make = which('gmake');
    unless (defined $make) {
        die "OS unsupported: GNU make ('gmake') is necessary to build the bundled hiredis.\n";
    }
}

my @make_args = ('-C', 'deps/hiredis', "CC=$Config{cc}", 'USE_WERROR=0', 'static');

# hiredis exchanges struct timeval with the XS: both need perl's time_t/off_t ABI
my @abi_flags = grep { /^-D_(?:TIME_BITS|FILE_OFFSET_BITS|LARGEFILE_SOURCE|LARGE_FILES)\b/ }
    split ' ', $Config{ccflags};
push @abi_flags, split ' ', $ENV{CPPFLAGS} if defined $ENV{CPPFLAGS};
push @make_args, "CPPFLAGS=@abi_flags" if @abi_flags;

if ($has_ssl) {
    push @make_args, 'USE_SSL=1';
    if (defined $ssl_detected && !ref $ssl_detected) {
        push @make_args, "OPENSSL_PREFIX=$ssl_detected";
    }
    elsif (ref $ssl_detected) {
        # hiredis only looks under OPENSSL_PREFIX, while pkg-config may
        # know a prefix the compiler does not search by default
        my $pc_prefix = `pkg-config --variable=prefix openssl 2>/dev/null`;
        if (defined $pc_prefix) {
            chomp $pc_prefix;
            push @make_args, "OPENSSL_PREFIX=$pc_prefix"
                if length $pc_prefix && -d "$pc_prefix/include/openssl";
        }
    }
}

# objects left by a build with other flags (another perl's ABI) must not be linked
system($make, '-C', 'deps/hiredis', 'clean') == 0
    or die "Failed to clean the bundled hiredis with '$make'.\n";
system($make, @make_args) == 0
    or die "Failed to build hiredis static library. Check that you have a C compiler and '$make' installed.\n";

if ($has_ssl) {
    my $ssl_lib = "deps/hiredis/libhiredis_ssl$Config{lib_ext}";
    die "Failed to build hiredis SSL library ($ssl_lib). Check OpenSSL installation.\n"
        unless -f $ssl_lib;
}

my @inc = ('-Isrc', '-Ideps/hiredis', "-I$installsitearch/EV", "-I$installsitearch");
push @inc, split(/\s+/, $ssl_cflags) if $ssl_cflags;

my @define = $has_ssl ? ('-DEV_REDIS_SSL') : ();

my @myextlib = ("deps/hiredis/libhiredis$Config{lib_ext}");
push @myextlib, "deps/hiredis/libhiredis_ssl$Config{lib_ext}" if $has_ssl;

my @libs;
push @libs, $ssl_libs if $ssl_libs;
# pthread_atfork: in libc on Linux, as EV assumes too
push @libs, '-lpthread' if $^O ne 'linux';

WriteMakefile(
    NAME             => 'EV::Redis',
    VERSION_FROM     => 'lib/EV/Redis.pm',
    ABSTRACT_FROM    => 'lib/EV/Redis.pm',
    AUTHOR           => [
        'Daisuke Murase (typester)',
        'vividsnow',
    ],
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.012000',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'EV::MakeMaker'       => 0,
        'File::Which'          => 0,
    },
    PREREQ_PM => {
        'EV'       => '4.11',
        'XSLoader' => '0.02',
    },
    TEST_REQUIRES => {
        'Test::More'        => '0.98',
        'Test::RedisServer' => '0.23',
        'Test::TCP'         => '1.18',
        'Test::Deep'        => 0,
        'Devel::Refcount'   => 0,
        'Devel::Peek'       => 0,
    },

    INC      => join(' ', @inc),
    DEFINE   => join(' ', @define),
    MYEXTLIB => join(' ', @myextlib),
    LIBS     => [join(' ', @libs)],
    # hide bundled hiredis symbols; GNU ld/gold/lld only (Solaris/AIX reject it)
    ($^O =~ /^(?:linux|gnukfreebsd|freebsd|midnightbsd|dragonfly|openbsd|netbsd)$/
        ? (LDDLFLAGS => "$Config{lddlflags} -Wl,--exclude-libs,ALL") : ()),

    clean => { FILES => 'Redis.xs Redis.c' },

    test => { TESTS => (-d '.git' || $ENV{RELEASE_TESTING}) && -d 'xt'
                        ? 't/*.t xt/*.t' : 't/*.t' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-redis.git',
                web  => 'https://github.com/vividsnow/perl5-ev-redis',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-redis/issues',
            },
        },
        no_index => {
            directory => [qw(t xt deps src)],
        },
    },
);

sub MY::postamble {
    my @targets;
    for my $lib (@myextlib) {
        push @targets, "$lib :\n\t\@echo \"$lib already built\"\n";
    }
    push @targets, "Redis.xs : src/EV__Redis.xs\n\t\$(CP) src/EV__Redis.xs Redis.xs\n";
    push @targets, "Redis.c : typemap\n";
    push @targets, "Redis\$(OBJ_EXT) : src/libev_adapter.h src/ngx-queue.h deps/hiredis/dict.c deps/hiredis/dict.h\n";
    push @targets, "clean ::\n\t-$make -C deps/hiredis clean\n";
    return join "\n", @targets;
}
