use strict;
use warnings;
use Test::More;
use Config;

# Rebuild first:
#   perl Makefile.PL CCFLAGS="$Config{ccflags} -std=gnu11 -g -fsanitize=address"
#   make
# then run with AUTHOR_TESTING=1.
#
# The runtime is preloaded, not linked into the .so: an XS module is dlopened,
# and ASan refuses to start when its runtime is not first in the library list
# ("ASan runtime does not come first"). Linking -fsanitize into the .so does not
# help, which is also why LIBS carries no sanitizer flag.

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'TDLib.o not found; run make first' unless -f 'TDLib.o';

my $strings = `strings TDLib.o 2>/dev/null`;
plan skip_all => 'TDLib.o was not built with -fsanitize=address'
    unless $strings =~ /__asan_init/;

my $libasan = `$Config{cc} -print-file-name=libasan.so 2>/dev/null`;
chomp $libasan;
plan skip_all => 'libasan not found' unless $libasan && -f $libasan;

$ENV{LD_PRELOAD} = $libasan;
$ENV{ASAN_OPTIONS} = 'detect_leaks=0:abort_on_error=1';

# Positive control: prove the runtime really maps into the child before
# trusting any "clean" result. A sanitizer that never started reports nothing,
# and every test below would pass for the wrong reason.
my $mapped = `"$Config{perlpath}" -e 'open my \$f, "<", "/proc/self/maps" or exit 1; print grep { /libasan/ } <\$f>' 2>&1`;
plan skip_all => 'the ASan runtime did not load into a child process'
    unless $mapped =~ /libasan/;

my @tests = sort glob('t/[0-9][0-9]_*.t');
plan tests => scalar @tests;

for my $t (@tests) {
    my $out = `"$Config{perlpath}" -Iblib/lib -Iblib/arch $t 2>&1`;
    my $rc = $? >> 8;

    if ($out =~ /AddressSanitizer/i) {
        fail "$t: ASAN error detected";
        diag $out =~ s/^/  /gmr;
    } elsif ($rc != 0) {
        fail "$t: test failure (rc=$rc)";
        diag $out =~ s/^/  /gmr;
    } else {
        pass "$t: clean";
    }
}
