#!perl
use Test::More; 
use Finance::NASDAQ::Quote;

my @symbols = ('FNORD'); #, 'BROKE');
my @quotes  = ({ prc => '1.337',
                 sgn => '+',
                 net => '3.14',
                 pct => '2.71%',
                 vol => '31,337',
                 nam => 'fnordco', },);

# _as_text doesn't do the checking, quote does.
#               { prc => '1.23',
#                 sgn => undef, # !
#                 net => '123', });
my @results = ( 'fnordco (FNORD): $1.337, +3.14 (+2.71%), vol 31,337'); # , undef );

plan tests => scalar @symbols;

for my $t (0..$#symbols) {
    my ($s, $q, $e) = ($symbols[$t], $quotes[$t], $results[$t]);
    my $actual      = Finance::NASDAQ::Quote::_as_text($s, %$q);
    is($actual, $e);
}
