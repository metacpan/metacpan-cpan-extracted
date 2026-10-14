#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

# The core under ASan and UBSan with no perl in the process: xt/c/harness.c,
# built and run by xt/c/run.sh. Its TAP is relayed here one line for one test,
# so a failure names the check and not just the file.

plan skip_all => 'Author tests not required for installation'
    unless $ENV{RELEASE_TESTING};
plan skip_all => 'run from the dist root: no xt/c/run.sh'
    unless -f 'xt/c/run.sh' && -d 'include/hamt';
plan skip_all => 'no sh to run xt/c/run.sh with'
    if $^O eq 'MSWin32' || !grep { -x "$_/sh" } split /:/, ($ENV{PATH} // '');

my $cc = $ENV{CC} || $Config{cc};
plan skip_all => 'no compiler recorded in Config' unless $cc;

# A compiler that cannot link an ASan binary is a skip, not a failure: the
# harness is about this dist's code and not about the toolchain.
my $dir = tempdir(CLEANUP => 1);
{
    open my $fh, '>', "$dir/probe.c" or plan skip_all => "cannot write a probe: $!";
    print {$fh} "int main(void) { return 0; }\n";
    close $fh;
    my $log = `"$cc" -fsanitize=address,undefined -o "$dir/probe" "$dir/probe.c" 2>&1`;
    plan skip_all => "$cc does not build with -fsanitize=address,undefined"
        if $? != 0 || !-x "$dir/probe" || system("$dir/probe") != 0;
}

# Twice. First with every block the C library's own and of its exact size,
# which is what lets ASan see a byte past the end of one. Then with every
# allocation going through the pool, as it does in the built library, so
# every check runs again on blocks that have been used before.
local $ENV{CC} = $cc;
my $extra = $ENV{HAMT_HARNESS_CFLAGS} // '';
for my $mode (['', ''], ['-DHAMT_HARNESS_POOL', ' (pooled)']) {
    my ($flag, $tag) = @$mode;
    local $ENV{HAMT_HARNESS_CFLAGS} = "$extra $flag";
    my $out = `sh xt/c/run.sh "$dir" 2>"$dir/err"`;
    my $rc  = $? >> 8;
    my $err = do { local (@ARGV, $/) = ("$dir/err"); <> } // '';

    my ($seen, $planned) = (0, undef);
    for my $line (split /\n/, $out) {
        if ($line =~ /^(not )?ok \d+ - (.*)$/) {
            ok(!$1, "$2$tag");
            $seen++;
        }
        elsif ($line =~ /^1\.\.(\d+)$/) {
            $planned = $1;
        }
    }

    ok(defined $planned, "the harness ran to its plan line$tag")
        or diag("it stopped early, which is what a sanitizer report looks like:\n$err");
    is($seen, $planned, "and every planned check reported$tag") if defined $planned;
    is($rc, 0, "and it exited clean$tag");
    unlike($err, qr/ERROR: AddressSanitizer|runtime error:/, "with nothing from either sanitizer$tag")
        or diag($err);
    unlike($err, qr/warning:/, "and the core compiles without a warning under -Wall -Wextra$tag")
        or diag($err);
}

done_testing;
