#!/usr/bin/env perl

# t/02_samples.t; Couple of tests

use Lingua::JPN::Number;

my %R = qw(123    hyaku-ni-ju-san
           4773   yon-sen-nana-hyaku-nana-ju-san
           10000  ichi-man
           1000000000000 i-t-cho
          );

$|++; 
print "1..", scalar keys %R, "\n";
my($test) = 1;

foreach my $n (sort keys %R) {
    my $s = join '-', Lingua::JPN::Number::to_string($n);
    if($s eq $R{$n}) {
        print "ok $test\n";
    } else {
        print "not ok $test\n";
    }
    $test++;
}
