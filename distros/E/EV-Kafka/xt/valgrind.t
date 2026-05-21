use strict;
use warnings;
use Test::More;

plan skip_all => 'set VALGRIND_TEST to run' unless $ENV{VALGRIND_TEST};
plan skip_all => 'valgrind not found' unless `which valgrind 2>/dev/null`;
plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};

my @tests = glob('t/0[0-9]_*.t t/1[0-4]_*.t');
plan tests => scalar @tests;

# Use the bundled perl suppressions if present — they filter out the
# routine optree-construction "possibly lost" noise that fires before
# any of our XS code runs.
my $supp = -f 'xt/perl.supp' ? '--suppressions=xt/perl.supp' : '';

for my $t (sort @tests) {
    my $cmd = "valgrind --leak-check=full --num-callers=20 $supp"
        . " $^X -Iblib/lib -Iblib/arch $t 2>&1";
    my $out = `$cmd`;

    my ($definitely) = $out =~ /definitely lost: ([\d,]+)/;
    $definitely //= '0';
    $definitely =~ s/,//g;

    my ($invalid) = $out =~ /Invalid (read|write)/;

    if ($invalid) {
        fail "$t: invalid $invalid detected";
        diag $out =~ s/^/  /gmr;
    } elsif ($definitely > 0) {
        fail "$t: $definitely bytes definitely lost";
        diag $out =~ s/^/  /gmr;
    } else {
        pass "$t: clean (definitely lost=$definitely)";
    }
}
