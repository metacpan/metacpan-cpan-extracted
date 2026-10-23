use strict;
use warnings;
use Test::More;
use Config;

# The reader thread hands (client_id, json) pairs to the EV drain through a
# mutex-protected queue and ev_async; that hand-off is what TSAN is for.
#
# TSan cannot be preloaded into an ordinary perl -- the runtime must be present
# from process start, and LD_PRELOAD either segfaults or silently fails to
# initialise, which makes every test look clean. So this needs a perl built
# with -fsanitize=thread; CI builds one. Then:
#   perl Makefile.PL CCFLAGS="$Config{ccflags} -std=gnu11 -g -fsanitize=thread"
#   make
# and run with AUTHOR_TESTING=1.

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'TDLib.o not found; run make first' unless -f 'TDLib.o';

my $strings = `strings TDLib.o 2>/dev/null`;
plan skip_all => 'TDLib.o was not built with -fsanitize=thread'
    unless $strings =~ /__tsan_init/;

my $instrumented = join(' ', $Config{ccflags}, $Config{optimize}, $Config{ldflags} // '')
    =~ /-fsanitize=thread/;
plan skip_all => "$Config{perlpath} was not built with -fsanitize=thread; "
    . 'TSan cannot be preloaded into an uninstrumented perl'
    unless $instrumented;

# TDLib itself is not instrumented and runs many threads of its own; without
# this every run drowns in reports from code we did not build.
my $supp = 'xt/tsan-suppressions.txt';
$ENV{TSAN_OPTIONS} = 'ignore_noninstrumented_modules=1:halt_on_error=1'
    . ':abort_on_error=1' . (-f $supp ? ":suppressions=$supp" : '');

# Positive control: prove the runtime really maps into the child before trusting
# any "clean" result. A sanitizer that never started reports nothing, and every
# test below would pass for the wrong reason.
my $mapped = `"$Config{perlpath}" -e 'open my \$f, "<", "/proc/self/maps" or exit 1; print grep { /libtsan/ } <\$f>' 2>&1`;
plan skip_all => 'the TSan runtime did not load into a child process'
    unless $mapped =~ /libtsan/;

# transport exercises the reader-to-drain queue, multi_client exercises
# concurrent routing through the shared client table
my @tests = qw(t/02_transport.t t/08_multi_client.t);
plan tests => scalar @tests;

for my $t (@tests) {
    my $out = `"$Config{perlpath}" -Iblib/lib -Iblib/arch $t 2>&1`;
    # The signal matters more than the exit code here: a child killed by
    # SIGSEGV or SIGABRT has rc 0, which is exactly the crash this harness exists
    # to catch.
    my $status = $?;
    my $rc  = $status >> 8;
    my $sig = $status & 127;

    if ($out =~ /ThreadSanitizer/i) {
        fail "$t: TSAN report";
        diag $out =~ s/^/  /gmr;
    } elsif ($sig) {
        fail "$t: killed by signal $sig";
        diag $out =~ s/^/  /gmr;
    } elsif ($rc != 0) {
        fail "$t: test failure (rc=$rc)";
        diag $out =~ s/^/  /gmr;
    } else {
        pass "$t: clean";
    }
}
