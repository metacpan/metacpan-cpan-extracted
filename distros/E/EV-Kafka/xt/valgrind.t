use strict;
use warnings;
use Test::More;

plan skip_all => 'set VALGRIND_TEST to run' unless $ENV{VALGRIND_TEST};
plan skip_all => 'valgrind not found' unless `which valgrind 2>/dev/null`;
plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};

my @tests = glob('t/0[0-9]_*.t t/1[0-4]_*.t');
plan tests => scalar @tests;

for my $t (sort @tests) {
    my $cmd = "valgrind --leak-check=full --error-exitcode=42"
        . " --suppressions=/dev/null"
        . " --num-callers=20"
        . " $^X -Iblib/lib -Iblib/arch $t 2>&1";
    my $out = `$cmd`;
    my $rc = $? >> 8;

    my ($definitely) = $out =~ /definitely lost: ([\d,]+)/;
    $definitely //= '0';
    $definitely =~ s/,//g;

    if ($rc == 42) {
        fail "$t: valgrind detected errors";
        diag $out =~ s/^/  /gmr;
    } elsif ($definitely > 0) {
        fail "$t: $definitely bytes definitely lost";
        diag $out =~ s/^/  /gmr;
    } else {
        pass "$t: clean";
    }
}
