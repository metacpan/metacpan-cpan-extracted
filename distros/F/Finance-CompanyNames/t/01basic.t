use strict;
use Finance::CompanyNames;
use Test::Simple tests => 6;

my $n;

$n = 0;

ok(1);

my $href = {INTC => 'Intel'};

Finance::CompanyNames::Init($href);

ok(1);

$href = Finance::CompanyNames::Match("Intel is a very large company");

ok(scalar(keys(%$href)) == 1);
ok(exists($href->{INTC}));
ok(exists($href->{INTC}->{freq}) && $href->{INTC}->{freq} == 1);
ok(exists($href->{INTC}->{contexts}) && scalar(@{$href->{INTC}->{contexts}}) == 1);

1;
