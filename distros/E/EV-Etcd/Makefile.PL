use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Find EV module's include path for EVAPI.h
use EV;
use File::Basename;
my $ev_inc = dirname($INC{'EV.pm'});  # Directory containing EV.pm (with EV/ subdir)
my $ev_inc_path = "-I$ev_inc";

# Try pkg-config for grpc
my $grpc_cflags = `pkg-config --cflags grpc 2>/dev/null` || '';
my $grpc_libs = `pkg-config --libs grpc 2>/dev/null` || '-lgrpc';
chomp($grpc_cflags, $grpc_libs);

# Try pkg-config for libprotobuf-c
my $protobuf_c_cflags = `pkg-config --cflags libprotobuf-c 2>/dev/null` || '';
my $protobuf_c_libs = `pkg-config --libs libprotobuf-c 2>/dev/null` || '-lprotobuf-c';
chomp($protobuf_c_cflags, $protobuf_c_libs);

# Detect gRPC API version for channel creation compatibility
# - gRPC >= ~1.42: grpc_insecure_credentials_create() + grpc_channel_create()
# - gRPC <  ~1.42: grpc_insecure_channel_create()
# The new API header moved from grpc_security.h to credentials.h in ~1.65
use File::Temp qw(tempdir);
my $grpc_api_defines = '';
my $tmpdir = tempdir(CLEANUP => 1);

sub try_compile {
    my ($cflags, $code) = @_;
    open my $fh, '>', "$tmpdir/test.c" or return 0;
    print $fh $code;
    close $fh;
    my $cc = $Config{cc} || 'cc';
    return system("$cc $cflags -Werror=implicit-function-declaration -c $tmpdir/test.c -o $tmpdir/test.o 2>/dev/null") == 0;
}

my $all_cflags = "$grpc_cflags $protobuf_c_cflags";

# Verify grpc and protobuf-c headers are available
unless (try_compile($all_cflags, <<'END')) {
#include <grpc/grpc.h>
#include <protobuf-c/protobuf-c.h>
int main(void) { return 0; }
END
    warn <<'MSG';
*******************************************
EV::Etcd requires libgrpc and libprotobuf-c
development headers to build.

Install them with:
  Debian/Ubuntu:  apt install libgrpc-dev libgrpc++-dev libprotobuf-c-dev
  macOS:          brew install grpc protobuf-c
  FreeBSD:        pkg install grpc protobuf-c
*******************************************
MSG
    exit 0;  # exit 0 = NA on CPAN Testers (not a test failure)
}

# Check for grpc/credentials.h (gRPC >= ~1.65)
if (try_compile($all_cflags, <<'END')) {
#include <grpc/credentials.h>
int main(void) { return 0; }
END
    $grpc_api_defines .= ' -DHAVE_GRPC_CREDENTIALS_H';
    print "Detected <grpc/credentials.h>\n";
}

# Check for new credentials-based channel API
my $creds_test_header = ($grpc_api_defines =~ /HAVE_GRPC_CREDENTIALS_H/)
    ? '#include <grpc/credentials.h>' : '#include <grpc/grpc_security.h>';
if (try_compile("$all_cflags $grpc_api_defines", <<"END")) {
#include <grpc/grpc.h>
$creds_test_header
void test(void) { grpc_channel_credentials *c = grpc_insecure_credentials_create(); (void)c; }
int main(void) { return 0; }
END
    $grpc_api_defines .= ' -DHAVE_GRPC_NEW_CHANNEL_API';
    print "Detected grpc_insecure_credentials_create (new channel API)\n";
} else {
    print "Using legacy grpc_insecure_channel_create\n";
}

WriteMakefile(
    NAME              => 'EV::Etcd',
    VERSION_FROM      => 'lib/EV/Etcd.pm',
    ABSTRACT_FROM     => 'lib/EV/Etcd.pm',
    AUTHOR            => 'vividsnow',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.010',

    # Explicit module map — without this, MakeMaker's auto-detection picks
    # up the top-level bench.pl script and tries to install it as a library.
    PM => {
        'lib/EV/Etcd.pm' => '$(INST_LIB)/EV/Etcd.pm',
    },

    PREREQ_PM => {
        'EV' => 0,
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'EV'                  => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => 0,
    },

    LIBS   => ["$grpc_libs $protobuf_c_libs -lpthread"],
    INC    => "-I. $ev_inc_path $grpc_cflags $protobuf_c_cflags",
    OBJECT => '$(O_FILES)',
    C      => ['Etcd.c', 'kv.pb-c.c', 'rpc.pb-c.c', 'lock.pb-c.c', 'election.pb-c.c',
               'cluster.pb-c.c', 'etcd_common.c', 'etcd_kv.c', 'etcd_watch.c',
               'etcd_lease.c', 'etcd_maint.c', 'etcd_lock.c', 'etcd_election.c',
               'etcd_cluster.c'],
    CCFLAGS => "$Config{ccflags} -std=c99$grpc_api_defines",

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-etcd.git',
                web  => 'https://github.com/vividsnow/perl5-ev-etcd',
            },
        },
    },
);
