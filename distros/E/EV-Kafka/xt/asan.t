use strict;
use warnings;
use Test::More;
use Config;

plan skip_all => 'set ASAN_TEST to run' unless $ENV{ASAN_TEST};
plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};

my $libasan = `$Config{cc} -print-file-name=libasan.so 2>/dev/null`;
chomp $libasan;
plan skip_all => 'libasan not found' unless $libasan && -f $libasan;

my @tests = glob('t/0[0-9]_*.t t/1[0-4]_*.t');
plan tests => scalar @tests;

$ENV{LD_PRELOAD} = $libasan;
$ENV{ASAN_OPTIONS} = 'detect_leaks=0:abort_on_error=1';

for my $t (sort @tests) {
    my $out = `$^X -Iblib/lib -Iblib/arch $t 2>&1`;
    my $rc = $? >> 8;

    if ($rc != 0 && $out =~ /AddressSanitizer/i) {
        fail "$t: ASAN error detected";
        diag $out =~ s/^/  /gmr;
    } elsif ($rc != 0 && $out =~ /FAIL/) {
        fail "$t: test failure (rc=$rc)";
    } else {
        pass "$t: clean";
    }
}
