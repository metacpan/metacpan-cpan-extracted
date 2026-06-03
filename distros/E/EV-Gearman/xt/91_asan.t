#!/usr/bin/env perl
# Author test: rebuild the XS with AddressSanitizer and re-run the
# leak/churn and large-payload scenarios under it. Catches heap
# overflow, use-after-free, and double-free that valgrind's leak
# pass (xt/90) does not focus on.
#
# Unlike valgrind, ASan needs compile-time instrumentation, so this
# compiles a throwaway instrumented copy of the already-generated
# Gearman.c into a tempdir and loads it via LD_PRELOAD=libasan —
# the user's blib is left untouched.
#
# Skipped unless EV_GEARMAN_ASAN=1. Requires a gcc/clang with
# -fsanitize=address, a findable libasan.so, a prior `make` (so
# Gearman.c exists), and a live gearmand.
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

plan skip_all => 'set EV_GEARMAN_ASAN=1 to enable' unless $ENV{EV_GEARMAN_ASAN};

my $cc = $Config{cc};
# Toolchain must support -fsanitize=address.
{
    my $probe = "/tmp/ev_gm_asan_probe_$$.c";
    open my $fh, '>', $probe or plan skip_all => "cannot write probe: $!";
    print $fh "int main(void){return 0;}\n";
    close $fh;
    my $ok = system("$cc -fsanitize=address -o $probe.out $probe >/dev/null 2>&1") == 0;
    unlink $probe, "$probe.out";
    plan skip_all => "$cc lacks -fsanitize=address" unless $ok;
}

# Locate the ASan runtime to preload into the (uninstrumented) perl.
chomp(my $libasan = `$cc -print-file-name=libasan.so 2>/dev/null`);
plan skip_all => 'libasan.so not found'
    unless $libasan && $libasan ne 'libasan.so' && -e $libasan;

# ASan reserves a huge (multi-TB) shadow region, which fails under
# `ulimit -v`/`-d` or in containers with a restricted address space.
# Probe once so such environments skip rather than report false bugs.
{
    local $ENV{LD_PRELOAD}   = $libasan;
    local $ENV{ASAN_OPTIONS} = 'detect_leaks=0';
    my $out = `$^X -e 0 2>&1`;
    plan skip_all => 'ASan runtime cannot initialize here (ulimit -v / restricted address space)'
        if $? != 0
        || $out =~ /ReserveShadowMemoryRange|failed to allocate|Perhaps you're using ulimit/;
}

plan skip_all => 'Gearman.c not built (run make first)' unless -f 'Gearman.c';

# EV's headers, exactly as Makefile.PL resolves them.
my $evinc = eval {
    require EV::MakeMaker;
    no warnings 'once';
    $EV::MakeMaker::installsitearch;
} || $Config{sitearch};

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
require IO::Socket::INET;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

# ---- build an ASan-instrumented Gearman.so into a tempdir ----
my $tmp = tempdir(CLEANUP => 1);
make_path("$tmp/auto/EV/Gearman");

my $obj = "$tmp/Gearman.o";
my $so  = "$tmp/auto/EV/Gearman/Gearman.so";

my $compile = join ' ', $cc,
    $Config{ccflags}, $Config{cccdlflags}, '-fsanitize=address -g -O1',
    '-Isrc', "-I$evinc/EV", "-I$evinc", "-I$Config{archlibexp}/CORE",
    qq{-DVERSION=\\"0.01\\" -DXS_VERSION=\\"0.01\\"},
    '-o', $obj, '-c', 'Gearman.c';

my $link = join ' ', $cc, '-fsanitize=address', $Config{lddlflags},
    $obj, '-o', $so;

diag "compiling instrumented Gearman.o";
is system("$compile 2>$tmp/build.log"), 0, 'ASan compile succeeded'
    or do { diag `cat $tmp/build.log`; done_testing; exit };
diag "linking instrumented Gearman.so";
is system("$link 2>>$tmp/build.log"), 0, 'ASan link succeeded'
    or do { diag `cat $tmp/build.log`; done_testing; exit };

# ---- run scenarios under ASan ----
# Pure-perl from blib/lib, instrumented .so from $tmp. detect_leaks=0:
# leak coverage is xt/90's job (perl leaks benignly at exit); here we
# want the memory-error checks. exitcode=98 marks an ASan abort.
my %child_env = (
    %ENV,
    LD_PRELOAD  => $libasan,
    ASAN_OPTIONS => 'detect_leaks=0:abort_on_error=0:exitcode=98:'
                  . 'halt_on_error=0:detect_stack_use_after_return=1',
    TEST_GEARMAN_HOST => $host,
    TEST_GEARMAN_PORT => $port,
);

for my $scenario (qw(xt/89_leak.t xt/16_buffer_shrink.t t/18_admin_disconnect.t)) {
    my $log = "$tmp/run.log";
    my $cmd = join ' ',
        map { /\s/ ? "'$_'" : $_ }
        ($^X, "-I$tmp", '-Iblib/lib', $scenario);
    my $rc = do {
        local %ENV = %child_env;
        system("$cmd >$log 2>&1");
    };
    my $exit = $rc >> 8;
    my $out  = '';
    if (open my $f, '<', $log) { local $/; $out = <$f> // ''; close $f; }

    my $sanitizer_clean = $out !~ /ERROR: AddressSanitizer|runtime error:|SUMMARY: AddressSanitizer/;
    ok $exit != 98,        "$scenario: no ASan abort";
    ok $sanitizer_clean,   "$scenario: no AddressSanitizer error in output";
    ok $exit == 0,         "$scenario: scenario exits cleanly under ASan";

    diag $out if $exit != 0 || !$sanitizer_clean;
}

done_testing;
