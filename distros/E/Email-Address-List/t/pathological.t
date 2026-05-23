use strict; use warnings;
use Test::More;
use Email::Address::List;
use Time::HiRes;

my @cases = (
    "a" x 25,
    "a " x 25,
    'a()' x 25,
    '() ' x 2000,
);

{
    # This test case is from the CVE-2015-7686 report
    open my $f, "<", "t/data/pathological.txt";
    my $line = <$f>;
    chomp $line;
    push @cases, $line;
}

for my $testcase (@cases) {
    my $start = Time::HiRes::time();
    my @addresses = Email::Address::List->parse($testcase);

    # Realistic expected is ~0.0001s.  In the pathological case, however, it
    # will take ~80s.  0.5s is thus unlikely to trip either false-positive
    # of false-negative, being approximitely two orders of magnitude away
    # from both.  We use actual elapsed time, rather than alarm(), for
    # portability.
    ok(Time::HiRes::time() - $start < 0.5,
       "Extracting from >>$testcase<< should take finite time");
}

done_testing();
