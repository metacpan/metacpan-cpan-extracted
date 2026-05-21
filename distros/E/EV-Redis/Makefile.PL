use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use File::Copy qw(copy);
use File::Which qw(which);
use EV::MakeMaker '$installsitearch';

die "OS unsupported\n" if $^O eq "MSWin32";

# Generate ppport.h if needed
unless (-f 'src/ppport.h') {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('src/ppport.h');
}

# Copy XS source to top-level for MakeMaker
copy('src/EV__Redis.xs', 'Redis.xs')
    or die "Cannot copy src/EV__Redis.xs -> Redis.xs: $!\n";

# --- SSL detection ---

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

my $want_ssl = $ENV{EV_REDIS_SSL};
my ($has_ssl, $ssl_cflags, $ssl_libs, $ssl_detected) = (0, '', '', undef);

if (!defined $want_ssl || $want_ssl) {
    $ssl_detected = _detect_openssl();
    if ($ssl_detected) {
        $has_ssl = 1;
        if (ref $ssl_detected eq 'HASH') {
            ($ssl_cflags, $ssl_libs) = ($ssl_detected->{cflags}, $ssl_detected->{libs});
        } else {
            ($ssl_cflags, $ssl_libs) = ("-I$ssl_detected/include", "-L$ssl_detected/lib -lssl -lcrypto");
        }
    } elsif ($want_ssl) {
        die "EV_REDIS_SSL=1 but OpenSSL not found. Install OpenSSL development headers or set OPENSSL_PREFIX.\n";
    }
}

print $has_ssl
    ? "Building with TLS support\n"
    : "Building without TLS support (set EV_REDIS_SSL=1 to force)\n";

# --- Build hiredis static library ---

my $make;
if ($^O =~ m/bsd$/ && $^O !~ m/gnukfreebsd$/) {
    $make = which('gmake');
    unless (defined $make) {
        print "'gmake' is necessary for BSD platform.\n";
        exit 0;
    }
} else {
    $make = $Config{make};
}

my @make_args = ('-C', 'deps/hiredis', 'static');
if ($has_ssl) {
    push @make_args, 'USE_SSL=1';
    if (defined $ssl_detected && !ref $ssl_detected) {
        push @make_args, "OPENSSL_PREFIX=$ssl_detected";
    }
}

system($make, @make_args) == 0
    or die "Failed to build hiredis static library. Check that you have a C compiler and '$make' installed.\n";

if ($has_ssl) {
    my $ssl_lib = "deps/hiredis/libhiredis_ssl$Config{lib_ext}";
    die "Failed to build hiredis SSL library ($ssl_lib). Check OpenSSL installation.\n"
        unless -f $ssl_lib;
}

# --- Assemble flags ---

my @inc = ('-Isrc', '-Ideps/hiredis', "-I$installsitearch/EV", "-I$installsitearch");
push @inc, split(/\s+/, $ssl_cflags) if $ssl_cflags;

my @define = $has_ssl ? ('-DEV_REDIS_SSL') : ();

my @myextlib = ("deps/hiredis/libhiredis$Config{lib_ext}");
push @myextlib, "deps/hiredis/libhiredis_ssl$Config{lib_ext}" if $has_ssl;

my @libs;
push @libs, $ssl_libs if $ssl_libs;

# --- WriteMakefile ---

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
        'Test::RedisServer' => '0.12',
        'Test::TCP'         => '1.18',
        'Test::Deep'        => 0,
        'Devel::Refcount'   => 0,
    },

    INC      => join(' ', @inc),
    DEFINE   => join(' ', @define),
    MYEXTLIB => join(' ', @myextlib),
    LIBS     => [join(' ', @libs)],
    # Hide hiredis symbols to avoid clashes with other modules bundling hiredis
    ($^O !~ /darwin/ ? (LDDLFLAGS => "$Config{lddlflags} -Wl,--exclude-libs,ALL") : ()),

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

# hiredis is built during Makefile.PL; provide a no-op rule.
# Also make Redis.xs depend on src/EV__Redis.xs so editing the source
# triggers a rebuild without re-running `perl Makefile.PL`.
sub MY::postamble {
    my @targets;
    for my $lib (@myextlib) {
        push @targets, "$lib :\n\t\@echo \"$lib already built\"\n";
    }
    push @targets, "Redis.xs : src/EV__Redis.xs\n\t\$(CP) src/EV__Redis.xs Redis.xs\n";
    return join "\n", @targets;
}
